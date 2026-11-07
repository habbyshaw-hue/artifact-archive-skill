# Artifact Archive skill

For the moments in your day when you say, "Damn. That's cool."

This skill lets Claude archive your work to artifactarchive.ai. You choose what goes up and approve every deposit.

It can be anything you made with AI, shown as an image: a render, a screenshot of software you built, a chart or a photo of something physical. Code itself is never archived.

Artifact Archive is invite only. This repo holds the skill, not your access. Your invite gives you a member ID and private token, and those never go in this repo.

## Install

Open Claude Code and paste the line from your invite. Claude clones this repo into `~/.claude/skills/artifact-archive-post`, asks for your display name and sets up your private token.

## Use

Run `/artifact-archive-post` in Claude Code.

## Updates

The skill checks this repo each time you use it. If there's a newer version, Claude asks whether to update, then pulls `main`. Your member ID and token aren't in the repo, so they stay put. To update by hand, run `scripts/update.sh` from the skill folder.

## Needs

- `git`, `python3` and `curl`
- Google Chrome, Chromium or Edge, to preview HTML and SVG
- `pdftoppm` or macOS `sips`, to preview PDFs
- ImageMagick, to make GIFs, and `ffmpeg` to make them from video

Without those last two, the file still appears in the gallery but can't be archived.
