#!/usr/bin/env python3
"""Builds a local, numbered gallery of artifact candidates.

Exit 0: gallery built. Exit 3: nothing to show.
"""
import argparse
import datetime
import html
import json
import os
import shutil
import subprocess
import sys
import tempfile
import webbrowser
from pathlib import Path

IMAGE_TYPES = {".png", ".jpg", ".jpeg", ".webp", ".gif"}
BROWSER_TYPES = {".html", ".htm", ".svg"}
PDF_TYPES = {".pdf"}
ALL_TYPES = IMAGE_TYPES | BROWSER_TYPES | PDF_TYPES
BROWSERS = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
    "google-chrome", "chromium", "chromium-browser", "microsoft-edge",
]


def find_browser():
    for candidate in BROWSERS:
        if os.path.isabs(candidate):
            if os.path.exists(candidate):
                return candidate
        elif shutil.which(candidate):
            return shutil.which(candidate)
    return None


def shoot_browser(browser: str, address: str, target: Path, work: Path) -> bool:
    command = [
        browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        f"--user-data-dir={work / 'browser'}", "--window-size=1400,1000",
        "--virtual-time-budget=3000", f"--screenshot={target}", address,
    ]
    try:
        subprocess.run(command, capture_output=True, timeout=45)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return target.exists()


def render_pdf(source: Path, target: Path) -> bool:
    try:
        if shutil.which("pdftoppm"):
            stem = target.with_suffix("")
            subprocess.run(
                ["pdftoppm", "-png", "-singlefile", "-f", "1", "-l", "1", "-r", "130", str(source), str(stem)],
                capture_output=True, timeout=45,
            )
        elif shutil.which("sips"):
            subprocess.run(
                ["sips", "-s", "format", "png", str(source), "--out", str(target)],
                capture_output=True, timeout=45,
            )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return target.exists()


def make_preview(source: Path, number: int, work: Path, browser):
    kind = source.suffix.lower()
    if kind in IMAGE_TYPES:
        target = work / f"{number:02d}{'.jpg' if kind == '.jpeg' else kind}"
        shutil.copyfile(source, target)
        return target
    target = work / f"{number:02d}.png"
    if kind in PDF_TYPES:
        return target if render_pdf(source, target) else None
    if browser and shoot_browser(browser, source.as_uri(), target, work):
        return target
    return None


def write_page(items, work: Path) -> Path:
    cells = []
    for item in items:
        if item["preview"]:
            picture = f'<img src="{html.escape(Path(item["preview"]).name)}" alt="" loading="lazy">'
        else:
            picture = '<div class="none">No preview. This file can\'t be archived.</div>'
        cells.append(
            f'<li><div class="frame">{picture}</div><p><b>{item["number"]}</b> '
            f'{html.escape(item["name"])}<br><small>{html.escape(item["date"])}</small></p></li>'
        )
    page = work / "index.html"
    page.write_text(
        """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>Choose an artifact</title>
<style>
body{margin:0;padding:clamp(1.5rem,4vw,3.5rem);background:#fbfaf7;color:#25211d;font:1rem/1.4 "Iowan Old Style",Palatino,Georgia,serif}
h1{margin:0 0 .25rem;font-size:2.25rem;font-weight:400}
.hint{margin:0 0 3rem;color:#6a635b}
ul{display:grid;grid-template-columns:repeat(auto-fill,minmax(16rem,1fr));gap:3rem;margin:0;padding:0;list-style:none}
.frame{display:flex;align-items:center;justify-content:center;height:15rem}
img{max-width:100%;max-height:100%}
.none{color:#6a635b;font-style:italic}
p{margin:.75rem 0 0;overflow-wrap:anywhere}
b{color:#d9411e;font-weight:400;font-size:1.25rem}
small{color:#6a635b}
</style>
<h1>Choose an artifact</h1>
<p class="hint">Tell Claude the number you want to archive.</p>
<ul>"""
        + "".join(cells)
        + "</ul></html>\n"
    )
    return page


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--include", action="append", default=[], help="Artifact from this session")
    parser.add_argument("--limit", type=int, default=24)
    parser.add_argument("--no-open", action="store_true")
    args = parser.parse_args()

    included = [Path(p).expanduser().resolve() for p in args.include]
    included = [p for p in included if p.is_file() and p.suffix.lower() in ALL_TYPES]
    included.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    candidates = list(dict.fromkeys(included))[: args.limit]

    if not candidates:
        print("No artifacts found.")
        return 3

    work = Path(tempfile.mkdtemp(prefix="artifact-archive-"))
    browser = find_browser()
    items = []
    for number, source in enumerate(candidates, 1):
        preview = make_preview(source, number, work, browser)
        modified = datetime.datetime.fromtimestamp(source.stat().st_mtime)
        items.append({
            "number": number,
            "name": source.name,
            "date": modified.strftime("%-d %b %Y, %H:%M"),
            "source": str(source),
            "preview": str(preview) if preview else None,
        })

    shutil.rmtree(work / "browser", ignore_errors=True)
    page = write_page(items, work)
    manifest = work / "manifest.json"
    manifest.write_text(json.dumps(items, indent=2))

    for item in items:
        flag = "" if item["preview"] else "  (no preview, can't be archived)"
        print(f"{item['number']:>2}. {item['name']}  {item['date']}{flag}")
    print(f"\nGallery: {page}\nManifest: {manifest}")
    if not args.no_open:
        webbrowser.open(page.as_uri())
    return 0


if __name__ == "__main__":
    sys.exit(main())
