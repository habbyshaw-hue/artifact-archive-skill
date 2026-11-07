# Artifact Archive skill

This skill lets Claude archive your work to artifactarchive.ai. You choose what goes up and approve every deposit.

It can be anything you made with AI, shown as an image: a render, a screenshot of software you built, a chart or a photo of something physical. Code itself is never archived.

Artifact Archive is invite only. This repo holds the skill, not your access. Your invite gives you a member ID and private token, and those never go in this repo.

## Install

1. Open the invite link you were given, enter your name and download your zip.
2. Open the zip, then run `sh ~/Downloads/artifact-archive-post/install.sh` in Terminal.
3. Delete the zip. It holds your private token, and the site can't show it again.

## Use

Tell Claude: "Archive this to Artifact Archive."

## Updates

The skill checks this repo each time you use it. If there's a newer version, Claude asks whether to update. Your member ID and token are kept. To update by hand, run `scripts/update.sh` from the skill folder.

## Needs

- `python3` and `curl`
- Google Chrome, Chromium or Edge, to preview HTML and SVG
- `pdftoppm` or macOS `sips`, to preview PDFs
- ImageMagick, to make GIFs, and `ffmpeg` to make them from video

Without those last two, the file still appears in the gallery but can't be archived.
