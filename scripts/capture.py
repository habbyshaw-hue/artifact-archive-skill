#!/usr/bin/env python3
"""Screenshots a running web app, for archiving software by what it shows."""
import argparse
import shutil
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlparse

from gallery import find_browser, shoot_browser


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", required=True, help="Address of the running app")
    parser.add_argument("--out", required=True, help="PNG file to write")
    args = parser.parse_args()

    if urlparse(args.url).scheme not in ("http", "https"):
        print("Use an http or https address.", file=sys.stderr)
        return 1
    browser = find_browser()
    if not browser:
        print("Install Chrome, Chromium or Edge to capture a web app.", file=sys.stderr)
        return 1
    target = Path(args.out).expanduser().resolve()
    target.unlink(missing_ok=True)
    work = Path(tempfile.mkdtemp(prefix="artifact-archive-capture-"))
    try:
        captured = shoot_browser(browser, args.url, target, work)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    if not captured:
        print(f"Could not capture {args.url}.", file=sys.stderr)
        return 1
    print(f"Captured: {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
