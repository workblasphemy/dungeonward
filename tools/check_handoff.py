#!/usr/bin/env python3
"""Validate dungeonward handoff notes.

The push range is what CI checks. A code commit and its note commit must be
pushed together: this script fails the range when paths outside handoffs/ and
docs/ change and no new handoffs/NNNN_<slug>_<task>.md is added. It also fails
any single commit that adds a note and changes files outside handoffs/.

Usage:
  python3 tools/check_handoff.py --base <sha> --head <sha>
  python3 tools/check_handoff.py --self-test
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

SLUGS = (
    "codex",
    "gemini",
    "claude",
    "kimi",
    "groq",
    "deepseek",
    "grok",
    "owner",
)
SLUG_ALT = "|".join(SLUGS)
VERDICTS = {
    "APPROVED",
    "IMPLEMENTED",
    "CHANGES_REQUESTED",
    "BLOCKED",
    "IN_PROGRESS",
}
TYPES = {"review", "feature", "fix", "test-run", "docs"}
STATUS_KEYS = [
    "Seq",
    "Date",
    "Verdict",
    "Type",
    "Build/commit",
    "Feature/task IDs",
    "Reviewed note",
    "Next owner",
    "Next action",
]
NOTE_NAME = re.compile(rf"^(\d{{4}})_({SLUG_ALT})_([a-z0-9][a-z0-9-]*)\.md$")
LOOSE_NOTE = re.compile(r"^(\d{4})_([^_]+)_(.+)\.md$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2} (?:[01]\d|2[0-3]):[0-5]\d [A-Z]{2,5}$")
CLAIM_RE = re.compile(
    rf"^({SLUG_ALT}) @ (\d{{4}}) since \d{{4}}-\d{{2}}-\d{{2}} "
    r"(?:[01]\d|2[0-3]):[0-5]\d [A-Z]{2,5}$"
)
CLEAR_CLAIM = {"", "—", "–", "-"}


class Report:
    def __init__(self) -> None:
        self.lines: list[str] = []
        self.failures = 0
        self.warnings = 0

    def ok(self, message: str) -> None:
        self.lines.append(f"PASS: {message}")

    def fail(self, message: str) -> None:
        self.failures += 1
        self.lines.append(f"FAIL: {message}")

    def warn(self, message: str) -> None:
        self.warnings += 1
        self.lines.append(f"WARNING: {message}")

    def info(self, message: str) -> None:
        self.lines.append(f"INFO: {message}")

    def finish(self) -> str:
        status = "ok" if self.failures == 0 else "failed"
        self.lines.append(
            f"RESULT: {status} ({self.failures} failures, {self.warnings} warnings)"
        )
        return "\n".join(self.lines) + "\n"


def git(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=repo,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(detail or f"git {' '.join(args)} failed")
    return result


def parse_name_status(text: str) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in text.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        status = parts[0]
        if status.startswith(("R", "C")) and len(parts) >= 3:
            rows.append((status, parts[1]))
            rows.append((status, parts[2]))
        elif len(parts) >= 2:
            rows.append((status, parts[1]))
    return rows


def is_note_path(path: str) -> bool:
    return NOTE_NAME.match(Path(path).name) is not None and (
        path.startswith("handoffs/") and "/archive/" not in path and path.count("/") == 1
    )


def added_note(status: str, path: str) -> bool:
    return status.startswith("A") and is_note_path(path)


def commit_changes(repo: Path, sha: str) -> list[tuple[str, str]]:
    result = git(repo, "diff", "--name-status", f"{sha}^", sha)
    return parse_name_status(result.stdout)


def worktree_changes(repo: Path) -> list[tuple[str, str]]:
    diff = git(repo, "diff", "--name-status", "HEAD")
    rows = parse_name_status(diff.stdout)
    untracked = git(repo, "ls-files", "--others", "--exclude-standard")
    for path in untracked.stdout.splitlines():
        if path:
            rows.append(("A", path))
    return rows


def find_notes(repo: Path) -> list[tuple[str, str, Path]]:
    """Return (seq, slug, path) for notes under handoffs/ and handoffs/archive/."""
    root = repo / "handoffs"
    found: list[tuple[str, str, Path]] = []
    if not root.is_dir():
        return found
    for path in root.rglob("*.md"):
        relative = path.relative_to(repo).as_posix()
        if relative.startswith("handoffs/archive/"):
            name = path.name
        elif path.parent == root:
            name = path.name
        else:
            continue
        loose = LOOSE_NOTE.match(name)
        strict = NOTE_NAME.match(name)
        if loose or strict or re.match(r"^\d{4}_", name):
            found.append((relative, name, path))
    return found


def parse_status(text: str, *, at_start: bool) -> tuple[dict[str, str] | None, str | None]:
    body = text.lstrip("\ufeff")
    if at_start and not body.lstrip("\n").startswith("```status\n"):
        return None, "status block is not at the start of the note"
    match = re.search(r"^```status\n(.*?)\n```", body, re.M | re.S)
    if not match:
        return None, "status block fence is missing or not closed"
    fields: dict[str, str] = {}
    order: list[str] = []
    for line in match.group(1).splitlines():
        if not line.strip():
            return None, "status block contains a blank line"
        if ":" not in line:
            return None, f"status line is not Key: value ({line!r})"
        key, value = line.split(":", 1)
        key = key.strip()
        if key in fields:
            return None, f"duplicate status key {key}"
        fields[key] = value.strip()
        order.append(key)
    if order != STATUS_KEYS:
        return None, (
            "status keys must be exactly "
            + ", ".join(STATUS_KEYS)
            + f" (found {', '.join(order) or 'none'})"
        )
    return fields, None


def has_proof(text: str) -> str | None:
    missing = [
        label
        for label in ("Command:", "OS/environment:", "Godot version:")
        if label not in text
    ]
    if missing:
        return "APPROVED note is missing " + ", ".join(missing)
    log_line = re.search(r"(?m)^[-* ]*Log:\s*\S", text)
    extra_fence = text.count("```") > 2
    if "handoffs/logs/" not in text and not log_line and not extra_fence:
        return (
            "APPROVED note needs a log for each check: a non-empty Log: line, "
            "a fenced log, or a handoffs/logs/NNNN_*.log path"
        )
    return None


def check_notes(repo: Path, head: str, report: Report) -> dict[str, dict[str, str]]:
    entries = find_notes(repo)
    parsed: dict[str, dict[str, str]] = {}
    parsed_notes: list[tuple[str, dict[str, str]]] = []
    seqs: dict[str, list[str]] = {}
    if not entries:
        report.fail("no numbered handoff notes under handoffs/ or handoffs/archive/")
        return parsed

    for relative, name, path in entries:
        strict = NOTE_NAME.match(name)
        if not strict:
            report.fail(
                f"{relative} filename must be NNNN_<slug>_<short-task>.md "
                f"with slug one of: {', '.join(SLUGS)}"
            )
            continue
        seq, slug, _task = strict.groups()
        seqs.setdefault(seq, []).append(relative)
        text = path.read_text(encoding="utf-8")
        line_count = text.count("\n") + (0 if text.endswith("\n") or text == "" else 1)
        if text.endswith("\n"):
            line_count = text.count("\n")
        else:
            line_count = text.count("\n") + (1 if text else 0)
        if line_count > 150:
            report.warn(f"{relative} has {line_count} lines (limit is 150)")
        fields, error = parse_status(text, at_start=True)
        if error or fields is None:
            report.fail(f"{relative}: {error}")
            continue
        if fields["Seq"] != seq:
            report.fail(f"{relative}: Seq {fields['Seq']} does not match filename {seq}")
        if not DATE_RE.match(fields["Date"]):
            report.fail(
                f"{relative}: Date must be YYYY-MM-DD HH:MM TZ (got {fields['Date']!r})"
            )
        if fields["Verdict"] not in VERDICTS:
            report.fail(
                f"{relative}: Verdict {fields['Verdict']!r} is not one of "
                + ", ".join(sorted(VERDICTS))
            )
        if fields["Type"] not in TYPES:
            report.fail(
                f"{relative}: Type {fields['Type']!r} is not one of "
                + ", ".join(sorted(TYPES))
            )
        if fields["Next owner"] not in SLUGS:
            report.fail(
                f"{relative}: Next owner must be one slug of "
                + ", ".join(SLUGS)
                + f" (got {fields['Next owner']!r})"
            )
        for required in ("Build/commit", "Feature/task IDs", "Next action"):
            if not fields[required]:
                report.fail(f"{relative}: {required} is empty")
        reviewed = fields["Reviewed note"]
        if reviewed != "none" and not re.fullmatch(r"\d{4}", reviewed):
            report.fail(
                f"{relative}: Reviewed note must be a seq such as 0003, or none "
                f"(got {reviewed!r})"
            )
        if fields["Verdict"] == "APPROVED" and slug != "codex":
            report.fail(
                f"{relative}: Verdict APPROVED is only allowed when the filename "
                f"slug is codex (got {slug})"
            )
        if fields["Verdict"] == "APPROVED":
            proof_error = has_proof(text)
            if proof_error:
                report.fail(f"{relative}: {proof_error}")
        build = fields["Build/commit"]
        if not re.fullmatch(r"[0-9a-fA-F]{7,40}", build):
            report.fail(f"{relative}: Build/commit is not a commit hash ({build!r})")
        else:
            resolved = git(repo, "rev-parse", "--verify", "--quiet", f"{build}^{{commit}}", check=False)
            if resolved.returncode != 0:
                report.fail(f"{relative}: Build/commit {build} is not in this repository history")
            else:
                ancestor = git(
                    repo,
                    "merge-base",
                    "--is-ancestor",
                    resolved.stdout.strip(),
                    head,
                    check=False,
                )
                if ancestor.returncode != 0:
                    report.fail(
                        f"{relative}: Build/commit {build} is not an ancestor of {head}"
                    )
        parsed[seq] = fields
        parsed_notes.append((relative, fields))

    duplicate = False
    for seq, paths in sorted(seqs.items()):
        if len(paths) > 1:
            duplicate = True
            report.fail("duplicate sequence " + seq + ": " + ", ".join(paths))
    if not duplicate and seqs:
        report.ok(f"sequence numbers unique (highest {max(seqs)})")

    for _relative, _name, _path in entries:
        pass
    for relative, fields in parsed_notes:
        reviewed = fields["Reviewed note"]
        if reviewed != "none" and reviewed not in seqs:
            report.fail(
                f"{relative}: Reviewed note {reviewed} does not match an existing note"
            )

    if parsed_notes and not any(line.startswith("FAIL:") for line in report.lines):
        report.ok("numbered notes have the required status block, enums, date, and slug")
    return parsed


def check_latest(repo: Path, parsed: dict[str, dict[str, str]], report: Report) -> None:
    latest_path = repo / "handoffs" / "LATEST.md"
    if not latest_path.is_file():
        report.fail("handoffs/LATEST.md is missing")
        return
    if not parsed:
        return
    notes = find_notes(repo)
    seqs = []
    names = {}
    for relative, name, _path in notes:
        match = NOTE_NAME.match(name)
        if match:
            seqs.append(match.group(1))
            names[match.group(1)] = name
    if not seqs:
        return
    highest = max(seqs)
    expected_name = names[highest]
    text = latest_path.read_text(encoding="utf-8")
    if expected_name not in text:
        report.fail(f"LATEST.md does not name the highest note {expected_name}")
    else:
        report.ok(f"LATEST.md points at {expected_name}")
    next_match = re.search(r"(?m)^Next seq:\s*(\d{4})\s*$", text)
    expected_next = f"{int(highest) + 1:04d}"
    if not next_match:
        report.fail("LATEST.md is missing a `Next seq: NNNN` line")
    elif next_match.group(1) != expected_next:
        report.fail(
            f"LATEST.md Next seq is {next_match.group(1)}; expected {expected_next}"
        )
    else:
        report.ok(f"LATEST.md Next seq is {expected_next}")
    latest_fields, error = parse_status(text, at_start=False)
    if error or latest_fields is None:
        report.fail(f"LATEST.md status block: {error}")
        return
    note_path = None
    for relative, name, path in notes:
        if name == expected_name and "/archive/" not in relative:
            note_path = path
            break
    if note_path is None:
        for _relative, name, path in notes:
            if name == expected_name:
                note_path = path
                break
    if note_path is None:
        return
    note_fields, _note_error = parse_status(
        note_path.read_text(encoding="utf-8"),
        at_start=True,
    )
    if note_fields and latest_fields != note_fields:
        report.fail("LATEST.md status block does not match the highest note")
    elif note_fields:
        report.ok("LATEST.md status block matches the highest note")


def check_status_table(repo: Path, report: Report) -> None:
    path = repo / "handoffs" / "STATUS.md"
    if not path.is_file():
        report.fail("handoffs/STATUS.md is missing")
        return
    rows = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if not cells or cells[0] in {"Feature/task ID", ""}:
            continue
        if all(set(cell) <= set("-: ") for cell in cells):
            continue
        if len(cells) < 6:
            report.fail(f"STATUS.md row has fewer than 6 columns: {line}")
            continue
        rows += 1
        owner = cells[4]
        claim = cells[5]
        if owner not in SLUGS:
            report.fail(
                f"STATUS.md Next owner for {cells[0]} must be one slug of "
                + ", ".join(SLUGS)
                + f" (got {owner!r})"
            )
        if claim not in CLEAR_CLAIM and not CLAIM_RE.match(claim):
            report.fail(
                f"STATUS.md Claimed by for {cells[0]} must be — or "
                f"'<slug> @ <seq> since YYYY-MM-DD HH:MM TZ' (got {claim!r})"
            )
    if rows and not any(line.startswith("FAIL: STATUS.md") for line in report.lines):
        report.ok(f"STATUS.md slugs and claims ({rows} rows)")


def check_range(repo: Path, base: str, head: str, report: Report) -> None:
    if re.fullmatch(r"0{40}", base or ""):
        report.info("range check skipped because the push base is an all-zero sha")
        return
    commits = git(repo, "rev-list", "--reverse", f"{base}..{head}")
    range_rows: list[tuple[str, str]] = []
    if commits.stdout.strip():
        range_rows.extend(parse_name_status(git(repo, "diff", "--name-status", base, head).stdout))
    for sha in commits.stdout.splitlines():
        rows = commit_changes(repo, sha)
        outside = [path for _status, path in rows if not path.startswith("handoffs/")]
        if any(added_note(status, path) for status, path in rows) and outside:
            report.fail(
                f"commit {sha} adds a handoff note and also changes files outside "
                f"handoffs/: {', '.join(outside)}. Put those edits in an earlier "
                "code commit. The note commit may only touch handoffs/. Push the "
                "code commit and the note commit together."
            )
    worktree = worktree_changes(repo)
    if worktree:
        outside = [path for _status, path in worktree if not path.startswith("handoffs/")]
        if any(added_note(status, path) for status, path in worktree) and outside:
            report.fail(
                "uncommitted changes add a handoff note and also change files "
                "outside handoffs/: "
                + ", ".join(outside)
                + ". Commit the code first. The note commit may only touch handoffs/."
            )
        range_rows.extend(worktree)
    if not any(line.startswith("FAIL: commit") or line.startswith("FAIL: uncommitted") for line in report.lines):
        report.ok("no commit adds a note and also changes files outside handoffs/")
    outside_range = sorted(
        {
            path
            for _status, path in range_rows
            if not path.startswith("handoffs/") and not path.startswith("docs/")
        }
    )
    added = [
        path
        for status, path in range_rows
        if added_note(status, path)
    ]
    if outside_range and not added:
        report.fail(
            "push range changes files outside handoffs/ and docs/ without adding "
            "handoffs/NNNN_<slug>_<task>.md: "
            + ", ".join(outside_range)
            + ". Include the note commit in the same push."
        )
    elif outside_range:
        report.ok("changes outside handoffs/ and docs/ are covered by a new handoff note")
    else:
        report.ok("no changes outside handoffs/ and docs/")


def evaluate(repo: Path, base: str, head: str) -> Report:
    report = Report()
    resolved_head = git(repo, "rev-parse", "--verify", f"{head}^{{commit}}").stdout.strip()
    parsed = check_notes(repo, resolved_head, report)
    check_latest(repo, parsed, report)
    check_status_table(repo, report)
    if base:
        check_range(repo, base, resolved_head, report)
    return report


def repo_root() -> Path:
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(result.stderr.strip() or "not a git repository")
    return Path(result.stdout.strip())


def write_note(path: Path, seq: str, slug: str, build: str, verdict: str = "IMPLEMENTED", owner: str = "codex", reviewed: str = "none", extra: str = "") -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "```status\n"
        f"Seq: {seq}\n"
        "Date: 2026-10-29 13:57 UTC\n"
        f"Verdict: {verdict}\n"
        "Type: docs\n"
        f"Build/commit: {build}\n"
        "Feature/task IDs: sample\n"
        f"Reviewed note: {reviewed}\n"
        f"Next owner: {owner}\n"
        "Next action: Continue the sample task.\n"
        "```\n"
        "# Agent task handoff (fill only applicable fields)\n"
        f"{extra}\n",
        encoding="utf-8",
    )


def write_latest(repo: Path, seq: str, slug: str, task: str, build: str, verdict: str = "IMPLEMENTED") -> None:
    name = f"{seq}_{slug}_{task}.md"
    text = (
        "# Latest handoff\n\n"
        "```status\n"
        f"Seq: {seq}\n"
        "Date: 2026-10-29 13:57 UTC\n"
        f"Verdict: {verdict}\n"
        "Type: docs\n"
        f"Build/commit: {build}\n"
        "Feature/task IDs: sample\n"
        "Reviewed note: none\n"
        "Next owner: codex\n"
        "Next action: Continue the sample task.\n"
        "```\n\n"
        f"Note: [{name}]({name})\n\n"
        f"Next seq: {int(seq) + 1:04d}\n"
    )
    (repo / "handoffs" / "LATEST.md").write_text(text, encoding="utf-8")


def write_status(repo: Path, build: str) -> None:
    (repo / "handoffs" / "STATUS.md").write_text(
        "# Handoff status\n\n"
        "| Feature/task ID | Verdict | Last commit | Last note | Next owner | Claimed by |\n"
        "|---|---|---|---|---|---|\n"
        f"| sample | IMPLEMENTED | {build} | 0001 | codex | — |\n",
        encoding="utf-8",
    )


def commit_all(repo: Path, message: str) -> str:
    git(repo, "add", "-A")
    git(
        repo,
        "-c",
        "user.email=handoff-test@example.com",
        "-c",
        "user.name=Handoff Test",
        "commit",
        "-m",
        message,
    )
    return git(repo, "rev-parse", "HEAD").stdout.strip()


def expect(report: Report, ok: bool, needle: str, label: str) -> list[str]:
    text = "\n".join(report.lines)
    problems = []
    if ok and report.failures:
        problems.append(f"{label}: expected pass\n{text}")
    if not ok and report.failures == 0:
        problems.append(f"{label}: expected failure\n{text}")
    if needle and needle not in text:
        problems.append(f"{label}: missing {needle!r}\n{text}")
    return problems


def run_self_test() -> int:
    problems: list[str] = []
    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")

        (repo / "README.md").write_text("code\n", encoding="utf-8")
        (repo / "docs").mkdir()
        (repo / "docs" / "HANDOFF_PROTOCOL.md").write_text("protocol\n", encoding="utf-8")
        code = commit_all(repo, "code")

        write_note(repo / "handoffs" / "0001_grok_sample.md", "0001", "grok", code)
        write_latest(repo, "0001", "grok", "sample", code)
        write_status(repo, code)
        problems.extend(
            expect(evaluate(repo, base, "HEAD"), True, "covered by a new handoff note", "worktree note")
        )
        note = commit_all(repo, "note")
        problems.extend(expect(evaluate(repo, base, note), True, "status block matches", "two commits"))

        (repo / "docs" / "only.md").write_text("docs\n", encoding="utf-8")
        docs_head = commit_all(repo, "docs only")
        problems.extend(expect(evaluate(repo, note, docs_head), True, "no changes outside handoffs/ and docs/", "docs only"))

        (repo / "README.md").write_text("later code\n", encoding="utf-8")
        later = commit_all(repo, "later code without note")
        problems.extend(
            expect(
                evaluate(repo, docs_head, later),
                False,
                "without adding",
                "code push without note",
            )
        )

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        (repo / "README.md").write_text("same commit\n", encoding="utf-8")
        write_note(repo / "handoffs" / "0001_grok_sample.md", "0001", "grok", base)
        write_latest(repo, "0001", "grok", "sample", base)
        write_status(repo, base)
        mixed = commit_all(repo, "mixed")
        problems.extend(
            expect(
                evaluate(repo, base, mixed),
                False,
                "adds a handoff note and also changes files outside handoffs/",
                "mixed commit",
            )
        )

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        code = base
        write_note(
            repo / "handoffs" / "0001_grok_sample.md",
            "0001",
            "grok",
            code,
            verdict="APPROVED",
        )
        write_latest(repo, "0001", "grok", "sample", code, verdict="APPROVED")
        # LATEST written with IMPLEMENTED by helper when verdict passed; rewrite match.
        write_latest(repo, "0001", "grok", "sample", code, verdict="APPROVED")
        write_status(repo, code)
        head = commit_all(repo, "bad approved")
        problems.extend(
            expect(evaluate(repo, base, head), False, "only allowed when the filename slug is codex", "grok approved")
        )

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        proof = (
            "## Proof\n"
            "- Command: true\n"
            "- OS/environment: Linux test\n"
            "- Godot version: 4.7.2.stable\n"
            "- Log: ok\n"
        )
        write_note(
            repo / "handoffs" / "0001_codex_sample.md",
            "0001",
            "codex",
            base,
            verdict="APPROVED",
            extra=proof,
        )
        write_latest(repo, "0001", "codex", "sample", base, verdict="APPROVED")
        write_status(repo, base)
        head = commit_all(repo, "codex approved")
        problems.extend(expect(evaluate(repo, base, head), True, "status block matches", "codex approved"))

        text = (repo / "handoffs" / "0001_codex_sample.md").read_text(encoding="utf-8")
        text = text.replace("Log: ok\n", "Log:\n")
        (repo / "handoffs" / "0001_codex_sample.md").write_text(text, encoding="utf-8")
        bare = commit_all(repo, "missing log")
        problems.extend(
            expect(evaluate(repo, head, bare), False, "needs a log", "approved without log")
        )

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        write_note(repo / "handoffs" / "0001_chatgpt_sample.md", "0001", "grok", base)
        # filename slug is wrong; write_note name is chatgpt but helper args unused for name
        head = commit_all(repo, "bad slug")
        problems.extend(expect(evaluate(repo, base, head), False, "slug", "bad slug"))

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        write_note(repo / "handoffs" / "0001_grok_sample.md", "0001", "grok", base, reviewed="0009")
        write_latest(repo, "0001", "grok", "sample", base)
        write_status(repo, base)
        (repo / "handoffs" / "archive" / "m0").mkdir(parents=True)
        write_note(repo / "handoffs" / "archive" / "m0" / "0001_grok_sample.md", "0001", "grok", base)
        head = commit_all(repo, "dup and missing review")
        text = "\n".join(evaluate(repo, base, head).lines)
        if "duplicate sequence 0001" not in text:
            problems.append(f"duplicate: missing failure\n{text}")
        if "Reviewed note 0009" not in text:
            problems.append(f"reviewed note: missing failure\n{text}")

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        write_note(repo / "handoffs" / "0001_grok_sample.md", "0001", "grok", base, owner="model/role")
        write_latest(repo, "0001", "grok", "sample", base)
        latest = (repo / "handoffs" / "LATEST.md").read_text(encoding="utf-8")
        latest = latest.replace("Next owner: codex", "Next owner: model/role")
        (repo / "handoffs" / "LATEST.md").write_text(latest, encoding="utf-8")
        write_status(repo, base)
        head = commit_all(repo, "bad owner")
        problems.extend(
            expect(evaluate(repo, base, head), False, "Next owner must be one slug", "role placeholder")
        )

    with tempfile.TemporaryDirectory() as tmp:
        repo = Path(tmp)
        git(repo, "init", "-b", "feature/m0-foundation")
        (repo / "README.md").write_text("base\n", encoding="utf-8")
        base = commit_all(repo, "base")
        long_extra = "\n".join(f"line {i}" for i in range(160))
        write_note(repo / "handoffs" / "0001_grok_sample.md", "0001", "grok", base, extra=long_extra)
        write_latest(repo, "0001", "grok", "sample", base)
        write_status(repo, base)
        head = commit_all(repo, "long note")
        report = evaluate(repo, base, head)
        text = "\n".join(report.lines)
        if report.failures:
            problems.append(f"long note: expected warning only\n{text}")
        if "WARNING:" not in text or "150" not in text:
            problems.append(f"long note: missing warning\n{text}")

    if problems:
        sys.stderr.write("\n\n".join(problems) + "\n")
        print(f"SELF-TEST: failed ({len(problems)} problems)")
        return 1
    print("SELF-TEST: ok")
    return 0


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Validate dungeonward handoff notes.")
    parser.add_argument("--base", default="", help="Range start (exclusive). Push base sha.")
    parser.add_argument("--head", default="HEAD", help="Range end (inclusive). Defaults to HEAD.")
    parser.add_argument("--self-test", action="store_true", help="Run fixture checks in a temp repo.")
    args = parser.parse_args(argv)
    if args.self_test:
        return run_self_test()
    root = repo_root()
    base = args.base or args.head
    report = evaluate(root, base, args.head)
    sys.stdout.write(report.finish())
    return 1 if report.failures else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
