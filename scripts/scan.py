#!/usr/bin/env python3
"""Scans a text-based artifact for secrets. Exit 2 means it found something.

Binary files are skipped, so the agent must still look at the image itself.
"""
import re
import sys
from pathlib import Path

PATTERNS = {
    "private key": r"-----BEGIN [A-Z ]*PRIVATE KEY-----",
    "AWS key": r"\bAKIA[0-9A-Z]{16}\b",
    "API key": r"\b(?:sk|pk|rk)[-_](?:live|test|ant|proj)?[-_]?[A-Za-z0-9_-]{20,}\b",
    "GitHub token": r"\bgh[pousr]_[A-Za-z0-9]{30,}\b",
    "Slack token": r"\bxox[abprs]-[A-Za-z0-9-]{10,}\b",
    "Google key": r"\bAIza[0-9A-Za-z_-]{30,}\b",
    "JWT": r"\beyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b",
    "archive token": r"\baa_[a-f0-9]{64}\b",
    "assigned secret": r"(?i)\b(?:password|passwd|secret|api[_-]?key|access[_-]?token)\b[\"']?\s*[:=]\s*[\"'][^\"'\s]{6,}[\"']",
    "confidential marking": r"(?i)\b(?:confidential|do not distribute|internal use only)\b",
}
TEXT_TYPES = {".html", ".htm", ".svg", ".md", ".txt", ".json", ".css", ".js"}


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: scan.py FILE", file=sys.stderr)
        return 1
    path = Path(sys.argv[1])
    if path.suffix.lower() not in TEXT_TYPES:
        print(f"Skipped {path.name}: not a text file. Check the preview by eye.")
        return 0
    text = path.read_text(errors="replace")
    found = 0
    for label, pattern in PATTERNS.items():
        for match in re.finditer(pattern, text):
            line = text.count("\n", 0, match.start()) + 1
            print(f"{label} on line {line}")
            found += 1
    if found:
        print(f"Stop. {found} finding(s) in {path.name}.")
        return 2
    print(f"No secrets found in {path.name}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
