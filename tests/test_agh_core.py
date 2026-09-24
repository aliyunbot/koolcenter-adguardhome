import unittest
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from src.agh_core import (
    DNSUpstreamContract,
    PlatformProbe,
    PortCheck,
    ServiceStatus,
    build_reconcile_plan,
    parse_upstream_probe,
)


class ReconcilePlanTests(unittest.TestCase):
    def setUp(self):
        self.platform = PlatformProbe("koolcenter", "aarch64", "/opt")
        self.services = (
            ServiceStatus("adguardhome", True, True),
            ServiceStatus("smartdns", True, True),
        )
        self.ports = (PortCheck("127.0.0.1", 6053, True),)
        self.upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="listener_owner",
            verified_generation=0,
        )

    def plan(self, **changes):
        args = {
            "platform": self.platform,
            "services": self.services,
            "ports": self.ports,
            "upstream": self.upstream,
        }
        args.update(changes)
        return build_reconcile_plan(**args)

    def test_normal_plan_is_successful_and_dry_run(self):
        plan = self.plan()
        self.assertTrue(plan.success)
        self.assertTrue(plan.dry_run)
        self.assertEqual(plan.failures, ())
        self.assertIn("configure_adguardhome_upstream:127.0.0.1:7913", plan.actions)

    def test_port_conflict_fails_closed(self):
        ports = (PortCheck("127.0.0.1", 6053, False, "other-service"),)
        plan = self.plan(ports=ports)
        self.assertFalse(plan.success)
        self.assertTrue(any(item.startswith("port_conflict:") for item in plan.failures))

    def test_adguardhome_own_listener_is_allowed(self):
        ports = (PortCheck("127.0.0.1", 6053, False, "adguardhome"),)
        plan = self.plan(ports=ports)
        self.assertTrue(plan.success)
        self.assertTrue(plan.dry_run)

    def test_non_expected_owner_still_fails_closed(self):
        ports = (
            PortCheck(
                "127.0.0.1",
                6053,
                False,
                "adguardhome",
                expected_owner="smartdns",
            ),
        )
        plan = self.plan(ports=ports)
        self.assertFalse(plan.success)
        self.assertTrue(any(item.startswith("port_conflict:") for item in plan.failures))

    def test_wrong_upstream_fails_closed(self):
        plan = self.plan(upstream=DNSUpstreamContract("8.8.8.8", 53))
        self.assertFalse(plan.success)
        self.assertIn("invalid_upstream:expected_127.0.0.1:7913", plan.failures)

    def test_unknown_upstream_verification_fails_closed(self):
        plan = self.plan(upstream=DNSUpstreamContract("127.0.0.1", 7913))
        self.assertFalse(plan.success)
        self.assertIn("upstream_unverified:unknown:mode=auto:source=none", plan.failures)

    def test_listener_owner_verified_upstream_is_allowed(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="listener_owner",
            verified_generation=0,
        )
        self.assertTrue(self.plan(upstream=upstream).success)

    def test_verified_wrong_endpoint_fails_closed(self):
        upstream = DNSUpstreamContract(
            "127.0.0.2",
            7913,
            state="verified",
            source="listener_owner",
            verified_generation=0,
        )
        plan = self.plan(upstream=upstream)
        self.assertFalse(plan.success)
        self.assertIn("invalid_upstream:expected_127.0.0.1:7913", plan.failures)

    def test_failed_upstream_verification_fails_closed(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="failed",
            source="listener_owner",
            evidence="listener_missing",
            verified_generation=0,
        )
        plan = self.plan(upstream=upstream)
        self.assertFalse(plan.success)
        self.assertIn(
            "upstream_unverified:failed:mode=auto:source=listener_owner:listener_missing",
            plan.failures,
        )

    def test_runtime_config_candidate_does_not_verify_listener(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="candidate",
            source="runtime_config",
            verified_generation=0,
        )
        plan = self.plan(upstream=upstream)
        self.assertFalse(plan.success)
        self.assertIn(
            "upstream_unverified:candidate:mode=auto:source=runtime_config",
            plan.failures,
        )

    def test_runtime_config_with_current_verification_is_allowed(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="runtime_config",
            evidence="runtime_listener_probe",
            verified_generation=0,
        )
        self.assertTrue(self.plan(upstream=upstream).success)

    def test_runtime_config_without_listener_probe_evidence_is_blocked(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="runtime_config",
            evidence="config_value",
            verified_generation=0,
        )
        plan = self.plan(upstream=upstream)
        self.assertFalse(plan.success)
        self.assertIn(
            "upstream_unverified:verified:mode=auto:source=runtime_config:config_value",
            plan.failures,
        )

    def test_runtime_config_verified_state_requires_current_generation(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="runtime_config",
            lifecycle_generation=1,
            verified_generation=0,
        )
        plan = self.plan(upstream=upstream)
        self.assertFalse(plan.success)
        self.assertIn("upstream_verification_stale:reload_or_restart", plan.failures)

    def test_explicit_upstream_requires_connectivity_and_safety_validation(self):
        upstream = DNSUpstreamContract(
            "192.0.2.53",
            53,
            state="verified",
            source="explicit",
            mode="explicit",
            connectivity_validated=True,
            safety_validated=True,
            verified_generation=0,
        )
        self.assertTrue(self.plan(upstream=upstream).success)

        unvalidated = DNSUpstreamContract(
            "192.0.2.53",
            53,
            state="verified",
            source="explicit",
            mode="explicit",
            verified_generation=0,
        )
        plan = self.plan(upstream=unvalidated)
        self.assertFalse(plan.success)
        self.assertIn("explicit_upstream_not_reachable", plan.failures)
        self.assertIn("explicit_upstream_not_safety_validated", plan.failures)

    def test_explicit_loopback_dns_endpoints_are_blocked(self):
        for host in ("127.0.0.1", "localhost", "::1"):
            for port in (53, 6053):
                with self.subTest(host=host, port=port):
                    upstream = DNSUpstreamContract(
                        host,
                        port,
                        state="verified",
                        source="explicit",
                        mode="explicit",
                        connectivity_validated=True,
                        safety_validated=True,
                        verified_generation=0,
                    )
                    plan = self.plan(upstream=upstream)
                    self.assertFalse(plan.success)
                    self.assertIn(
                        f"explicit_upstream_loopback_safety_failure:{host}:{port}",
                        plan.failures,
                    )

    def test_explicit_smartdns_loopback_endpoint_remains_allowed(self):
        upstream = DNSUpstreamContract(
            "127.0.0.1",
            7913,
            state="verified",
            source="explicit",
            mode="explicit",
            connectivity_validated=True,
            safety_validated=True,
            verified_generation=0,
        )
        self.assertTrue(self.plan(upstream=upstream).success)

    def test_wrong_agh_listener_fails_closed(self):
        plan = self.plan(agh_listen=("0.0.0.0", 6053))
        self.assertFalse(plan.success)
        self.assertIn("invalid_agh_listen:expected_127.0.0.1:6053", plan.failures)

    def test_missing_service_fails_closed(self):
        plan = self.plan(services=(self.services[0],))
        self.assertFalse(plan.success)
        self.assertIn("service_unavailable:smartdns", plan.failures)


class UpstreamProbeParserTests(unittest.TestCase):
    def output(self, **changes):
        values = {
            "state": "verified",
            "source": "listener_owner",
            "host": "127.0.0.1",
            "port": "7913",
            "owner": "smartdns",
            "reason": "exact_loopback_listener_owned_by_smartdns",
            "read_only": "1",
        }
        values.update(changes)
        return "\n".join(f"{key}={value}" for key, value in values.items())

    def test_verified_probe_becomes_current_listener_owner_contract(self):
        contract = parse_upstream_probe(self.output(), lifecycle_generation=4)
        self.assertTrue(contract.verified)
        self.assertEqual(contract.source, "listener_owner")
        self.assertEqual(contract.evidence, "exact_loopback_listener_owned_by_smartdns")
        self.assertEqual(contract.verified_generation, 4)
        self.assertEqual(contract.lifecycle_generation, 4)

    def test_non_verified_probe_states_remain_unverified_and_preserve_reason(self):
        for state in ("unknown", "candidate", "failed"):
            with self.subTest(state=state):
                contract = parse_upstream_probe(
                    self.output(state=state, source="listener", owner="other", reason="probe_reason")
                )
                self.assertFalse(contract.verified)
                self.assertEqual(contract.state, state)
                self.assertEqual(contract.evidence, "probe_reason")

    def test_wrong_owner_or_source_cannot_verify(self):
        for changes in ({"owner": "other"}, {"owner": "unknown"}, {"source": "listener"}, {"source": "none"}):
            with self.subTest(changes=changes):
                self.assertFalse(parse_upstream_probe(self.output(**changes)).verified)

    def test_wrong_endpoint_cannot_verify(self):
        for changes in ({"host": "127.0.0.2"}, {"port": "7914"}):
            with self.subTest(changes=changes):
                self.assertFalse(parse_upstream_probe(self.output(**changes)).verified)

    def test_missing_duplicate_and_illegal_fields_fail_closed(self):
        valid = self.output()
        invalid_inputs = (
            "\n".join(line for line in valid.splitlines() if not line.startswith("owner=")),
            valid + "\nowner=smartdns",
            valid + "\nextra=value",
            valid.replace("state=verified", "state=bogus"),
            valid.replace("owner=smartdns", "owner=forged"),
        )
        for text in invalid_inputs:
            with self.subTest(text=text):
                contract = parse_upstream_probe(text)
                self.assertEqual(contract.state, "failed")
                self.assertFalse(contract.verified)
                self.assertTrue(contract.evidence.startswith("probe_parse_error:"))

    def test_read_only_must_be_exactly_one(self):
        for read_only in ("0", "true", "01"):
            with self.subTest(read_only=read_only):
                contract = parse_upstream_probe(self.output(read_only=read_only))
                self.assertEqual(contract.state, "failed")
                self.assertFalse(contract.verified)

    def test_package_evidence_is_not_relabelled_core(self):
        contract = parse_upstream_probe(self.output())
        self.assertEqual(contract.source, "listener_owner")


if __name__ == "__main__":
    unittest.main()
