from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".md", ".json", ".js", ".py", ".sh", ".txt"}
PRIVATE_MARKERS = (
    "192.0.2." + "1",  # TEST-NET-1 documentation address
    "198.51.100." + "1",  # TEST-NET-2 documentation address
    "100.64." + "0." + "1",  # RFC 6598 documentation address
    "router-" + "example",
    "router_" + "backups/",
    "admin@",
)


def public_text_files():
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix not in TEXT_SUFFIXES:
            continue
        if path.name == "test_public_documentation.py":
            continue
        if ".git" in path.parts or "__pycache__" in path.parts or ".pytest_cache" in path.parts:
            continue
        if path.parts[-2:] == ("package", "dist"):
            continue
        yield path


def test_public_tree_has_no_single_deployment_markers():
    violations = []
    for path in public_text_files():
        text = path.read_text(encoding="utf-8", errors="replace").lower()
        for marker in PRIVATE_MARKERS:
            if marker.lower() in text:
                violations.append(f"{path.relative_to(ROOT)}: {marker}")
    assert not violations, "private deployment marker found: " + "; ".join(violations)


def test_public_guides_include_chinese_entrypoint():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "README.zh-CN.md").read_text(encoding="utf-8")
    assert "中文" in readme
    assert "公开仓库卫生" in chinese
