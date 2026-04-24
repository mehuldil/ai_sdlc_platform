#!/usr/bin/env python3
"""CLI for unified semantic memory.

Examples:
  python scripts/semantic-memory.py status
  python scripts/semantic-memory.py upsert --orchestrator qa --namespace requirements --key US-1001 --content-file notes.md
  python scripts/semantic-memory.py query --text "oauth timeout edge case" --orchestrator qa --limit 5
  python scripts/semantic-memory.py lifecycle
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path


def _root_dir() -> Path:
    return Path(__file__).resolve().parents[1]


def _default_db_path() -> Path:
    env = os.environ.get("SDL_SEMANTIC_DB", "").strip()
    if env:
        return Path(env)
    here = Path.cwd().resolve()
    p = here
    for _ in range(24):
        if (p / ".git").exists():
            return p / ".sdlc" / "memory" / "semantic-memory.sqlite3"
        if p.parent == p:
            break
        p = p.parent
    return _root_dir() / ".sdlc" / "memory" / "semantic-memory.sqlite3"


def _default_team_export_path() -> Path:
    env = os.environ.get("SDL_SEMANTIC_EXPORT", "").strip()
    if env:
        return Path(env)
    here = Path.cwd().resolve()
    p = here
    for _ in range(24):
        if (p / ".git").exists():
            return p / ".sdlc" / "memory" / "semantic-memory-team.jsonl"
        if p.parent == p:
            break
        p = p.parent
    return _root_dir() / ".sdlc" / "memory" / "semantic-memory-team.jsonl"


def _ensure_import():
    root = str(_root_dir())
    if root not in sys.path:
        sys.path.insert(0, root)
    from orchestrator.shared.semantic_memory import UnifiedSemanticMemory  # noqa: WPS433

    return UnifiedSemanticMemory


def cmd_status(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    mem = UnifiedSemanticMemory(args.db)
    print(json.dumps(mem.stats(), indent=2))
    mem.close()
    return 0


def cmd_upsert(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    mem = UnifiedSemanticMemory(args.db)
    content = args.content
    if args.content_file:
        content = Path(args.content_file).read_text(encoding="utf-8")
    if not content:
        raise SystemExit("content is required (--content or --content-file)")
    metadata = {}
    if args.metadata:
        metadata = json.loads(args.metadata)
    result = mem.upsert(
        args.orchestrator,
        args.namespace,
        args.key,
        content,
        metadata,
        expected_version=args.expected_version,
        conflict_strategy=args.conflict_strategy,
    )
    print(json.dumps(result.__dict__, indent=2))
    mem.close()
    return 0


def cmd_query(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    mem = UnifiedSemanticMemory(args.db)
    results = mem.query(
        args.text,
        orchestrator=args.orchestrator,
        namespace=args.namespace,
        limit=args.limit,
        include_archived=args.include_archived,
    )
    print(json.dumps(results, indent=2))
    mem.close()
    return 0


def cmd_lifecycle(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    mem = UnifiedSemanticMemory(args.db)
    result = mem.apply_lifecycle_governance(
        archive_superseded_after_days=args.archive_days,
        retain_versions_per_key=args.retain_versions,
        hard_delete_archived_after_days=args.delete_days,
    )
    print(json.dumps(result, indent=2))
    mem.close()
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    mem = UnifiedSemanticMemory(args.db)
    rows = mem.export_active_latest()
    mem.close()
    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    print(json.dumps({"exported": len(rows), "path": str(out_path)}, indent=2))
    return 0


def cmd_import(args: argparse.Namespace) -> int:
    UnifiedSemanticMemory = _ensure_import()
    in_path = Path(args.input)
    if not in_path.is_file():
        print(json.dumps({"error": "missing_file", "path": str(in_path)}))
        return 1
    records: list[dict] = []
    with in_path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            records.append(json.loads(line))
    mem = UnifiedSemanticMemory(args.db)
    result = mem.import_team_export(records, conflict_strategy=args.conflict_strategy)
    mem.close()
    print(json.dumps(result, indent=2))
    return 0


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Unified semantic memory CLI")
    parser.add_argument("--db", default=str(_default_db_path()), help="SQLite db path")
    sub = parser.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("status", help="Show memory stats")
    s.set_defaults(func=cmd_status)

    s = sub.add_parser("upsert", help="Insert/update memory artifact")
    s.add_argument("--orchestrator", required=True)
    s.add_argument("--namespace", required=True)
    s.add_argument("--key", required=True)
    s.add_argument("--content", default="")
    s.add_argument("--content-file", default="")
    s.add_argument("--metadata", default="{}")
    s.add_argument("--expected-version", type=int, default=None)
    s.add_argument(
        "--conflict-strategy",
        default="reject",
        choices=["reject", "last_write_wins", "merge_append"],
    )
    s.set_defaults(func=cmd_upsert)

    s = sub.add_parser("query", help="Semantic query")
    s.add_argument("--text", required=True)
    s.add_argument("--orchestrator", default=None)
    s.add_argument("--namespace", default=None)
    s.add_argument("--limit", type=int, default=10)
    s.add_argument("--include-archived", action="store_true")
    s.set_defaults(func=cmd_query)

    s = sub.add_parser("lifecycle", help="Apply lifecycle governance")
    s.add_argument("--archive-days", type=int, default=30)
    s.add_argument("--retain-versions", type=int, default=5)
    s.add_argument("--delete-days", type=int, default=365)
    s.set_defaults(func=cmd_lifecycle)

    s = sub.add_parser("export", help="Export active memory to JSONL (for git / team sync)")
    s.add_argument("--output", "-o", default=str(_default_team_export_path()), help="JSONL output path")
    s.set_defaults(func=cmd_export)

    s = sub.add_parser("import", help="Import team JSONL into local SQLite")
    s.add_argument("--input", "-i", default=str(_default_team_export_path()), help="JSONL input path")
    s.add_argument(
        "--conflict-strategy",
        default="last_write_wins",
        choices=["reject", "last_write_wins", "merge_append"],
    )
    s.set_defaults(func=cmd_import)
    return parser


def main() -> int:
    args = _parser().parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())

