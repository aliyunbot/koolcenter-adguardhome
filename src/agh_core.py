"""Portable, side-effect-free core for AdGuard Home DNS-chain planning."""

from dataclasses import dataclass, field


AGH_LISTEN = ("127.0.0.1", 6053)
SMARTDNS_UPSTREAM = ("127.0.0.1", 7913)


@dataclass(frozen=True)
class PlatformProbe:
    platform: str
    architecture: str
    storage_path: str
    supported: bool = True


@dataclass(frozen=True)
class ServiceStatus:
    name: str
    installed: bool
    running: bool


@dataclass(frozen=True)
class PortCheck:
    host: str
    port: int
    available: bool
    owner: str | None = None
    expected_owner: str | None = "adguardhome"


@dataclass(frozen=True)
class DNSUpstreamContract:
    host: str
    port: int
    state: str = "unknown"
    source: str = "none"
    evidence: str | None = None
    mode: str = "auto"
    connectivity_validated: bool = False
    safety_validated: bool = False
    lifecycle_generation: int = 0
    verified_generation: int = -1

    @property
    def valid(self) -> bool:
        return (self.host, self.port) == SMARTDNS_UPSTREAM

    @property
    def verified(self) -> bool:
        if self.state not in ("verified", "active"):
            return False
        if self.verified_generation != self.lifecycle_generation:
            return False
        if self.mode == "auto":
            return self.source == "listener_owner" or (
                self.source == "runtime_config"
                and self.evidence == "runtime_listener_probe"
            )
        if self.mode == "explicit":
            return (
                self.source == "explicit"
                and not self.local_dns_loop
                and self.connectivity_validated
                and self.safety_validated
            )
        return False

    @property
    def local_dns_loop(self) -> bool:
        return self.host.lower().rstrip(".") in ("127.0.0.1", "localhost", "::1") and self.port in (53, 6053)


def parse_upstream_probe(text: str, lifecycle_generation: int = 0) -> DNSUpstreamContract:
    """Convert package probe stdout into a core contract without side effects."""
    required = {"state", "source", "host", "port", "owner", "reason", "read_only"}
    values: dict[str, str] = {}
    try:
        if not isinstance(text, str):
            raise ValueError("output_not_text")
        for line in text.splitlines():
            if not line or line.count("=") != 1:
                raise ValueError("malformed_line")
            key, value = line.split("=", 1)
            if key not in required:
                raise ValueError("unexpected_field")
            if key in values:
                raise ValueError("duplicate_field")
            if not value or value.strip() != value:
                raise ValueError("invalid_value")
            values[key] = value
        if values.keys() != required:
            raise ValueError("missing_field")
        if values["state"] not in {"unknown", "candidate", "verified", "failed"}:
            raise ValueError("invalid_state")
        if values["source"] not in {"none", "listener", "listener_owner"}:
            raise ValueError("invalid_source")
        if values["owner"] not in {"unknown", "smartdns", "other"}:
            raise ValueError("invalid_owner")
        if values["read_only"] != "1":
            raise ValueError("read_only_required")
        if not values["reason"] or any(ord(char) < 32 for char in values["reason"]):
            raise ValueError("invalid_reason")
        try:
            port = int(values["port"])
        except ValueError as exc:
            raise ValueError("invalid_port") from exc
        if not 1 <= port <= 65535:
            raise ValueError("invalid_port")
        host = values["host"]
    except (ValueError, TypeError) as exc:
        return DNSUpstreamContract(
            "127.0.0.1", 7913, state="failed", source="none",
            evidence=f"probe_parse_error:{exc}",
            lifecycle_generation=lifecycle_generation,
        )

    verified = (
        values["state"] == "verified"
        and values["source"] == "listener_owner"
        and values["owner"] == "smartdns"
        and host == "127.0.0.1"
        and port == 7913
    )
    return DNSUpstreamContract(
        host,
        port,
        state=values["state"],
        source=values["source"],
        evidence=values["reason"],
        mode="auto",
        lifecycle_generation=lifecycle_generation,
        verified_generation=lifecycle_generation if verified else -1,
    )


@dataclass(frozen=True)
class ReconcilePlan:
    success: bool
    dry_run: bool = True
    actions: tuple[str, ...] = ()
    failures: tuple[str, ...] = ()


def build_reconcile_plan(
    platform: PlatformProbe,
    services: tuple[ServiceStatus, ...],
    ports: tuple[PortCheck, ...],
    upstream: DNSUpstreamContract,
    agh_listen: tuple[str, int] = AGH_LISTEN,
) -> ReconcilePlan:
    """Validate prerequisites and describe intended work; never mutate a system."""
    failures: list[str] = []
    if not platform.supported:
        failures.append("platform_unsupported")

    service_map = {service.name: service for service in services}
    for name in ("adguardhome", "smartdns"):
        service = service_map.get(name)
        if service is None or not service.installed or not service.running:
            failures.append(f"service_unavailable:{name}")

    if upstream.mode == "auto" and not upstream.valid:
        failures.append("invalid_upstream:expected_127.0.0.1:7913")
    elif upstream.mode == "explicit" and (
        not upstream.host or not 1 <= upstream.port <= 65535
    ):
        failures.append("invalid_explicit_upstream:endpoint")
    elif upstream.mode not in ("auto", "explicit"):
        failures.append(f"invalid_upstream_mode:{upstream.mode}")
    if not upstream.verified:
        evidence = f":{upstream.evidence}" if upstream.evidence else ""
        failures.append(
            f"upstream_unverified:{upstream.state}:mode={upstream.mode}:source={upstream.source}{evidence}"
        )
    if upstream.mode == "explicit" and upstream.local_dns_loop:
        failures.append(
            f"explicit_upstream_loopback_safety_failure:{upstream.host}:{upstream.port}"
        )
    if upstream.mode == "explicit" and not upstream.connectivity_validated:
        failures.append("explicit_upstream_not_reachable")
    if upstream.mode == "explicit" and not upstream.safety_validated:
        failures.append("explicit_upstream_not_safety_validated")
    if upstream.verified_generation != upstream.lifecycle_generation:
        failures.append("upstream_verification_stale:reload_or_restart")

    if agh_listen != AGH_LISTEN:
        failures.append("invalid_agh_listen:expected_127.0.0.1:6053")

    port_map = {(port.host, port.port): port for port in ports}
    listener = port_map.get(AGH_LISTEN)
    if listener is None:
        failures.append("port_conflict:127.0.0.1:6053:unknown")
    elif not listener.available and not (
        listener.owner is not None
        and listener.owner == listener.expected_owner == "adguardhome"
    ):
        owner = listener.owner if listener and listener.owner else "unknown"
        failures.append(f"port_conflict:127.0.0.1:6053:{owner}")

    if failures:
        return ReconcilePlan(success=False, failures=tuple(failures))

    return ReconcilePlan(
        success=True,
        actions=(
            "configure_adguardhome_listen:127.0.0.1:6053",
            f"configure_adguardhome_upstream:{upstream.host}:{upstream.port}",
            "no_router_changes_dry_run",
        ),
    )
