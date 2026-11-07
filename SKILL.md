---
name: artifact-archive-post
description: Archive work to Artifact Archive (artifactarchive.ai), a members-only image wall of things people make with AI. Covers images, artifacts, renders, screenshots of software and tools, and anything else made with an agent. Use when the member says to archive, deposit, post or share something to Artifact Archive, or runs /artifact-archive-post. Asks whether to upload an image, search their artifacts or create something new. Also removes the member's own deposits when they ask to remove, delete or unarchive one.
---

# Archive to Artifact Archive

Artifact Archive is a private image wall of work people make with AI. A deposit is one image and one short note. Agents are the only way to archive.

Show the work running, or what it produced, not the code that made it.

Run the scripts from this skill's folder. Never print the member's token, and never add it to a command line.

## How the work is split

You talk to the member. Subagents do the heavy work, so the member's conversation stays clear. Subagents can't ask the member anything, so every question and approval stays with you.

- **Image work:** Spawn a subagent to make the image in step 3, whether that's running the work, capturing it, building a gallery or making a GIF. Tell it what the member chose, the rules in step 3 and the file to write. If it needs a decision, it must stop and return the question to you.
- **Archiving work:** After the member's yes in step 6, spawn a subagent to run step 7. Give it the exact image path and the exact note, and tell it the member has approved both. It must not change either one. It returns the deposit link or the error.

Never spawn the archiving subagent before that yes. Do the privacy check in step 5 yourself, and look at the image yourself, even if a subagent made it. If your host can't spawn subagents, do the work directly.

## 1. Check setup

Run `scripts/post.sh --check`. If it fails, show the member the message and point them to `README.md`. Stop.

If it says an update is available, tell the member and ask whether to update now. On a yes, run `scripts/update.sh`, read this file again, and follow the new version. On a no, carry on.

## 2. Ask what to archive

If the member has already attached or named what they want, go to step 3. Otherwise ask:

> What would you like to archive?
>
> 1. Upload an image
> 2. Search your artifacts
> 3. Create something new

Wait for their answer. Don't search for anything, read their files or build a gallery first.

## 3. Get the image

**Upload an image.** Use the image or path they give you as it is. It can be a render, a photo or a screen capture. The archive takes PNG, JPEG, WebP and GIF.

**Search your artifacts.** Ask what they're looking for, or whether to show everything from this session. Work only from what was made in this session, and don't scan folders. If an artifact exists only in the conversation or at a published link, save it to a temporary file first.

If they described one, find the file that matches. If nothing matches, or more than one thing could, ask them. Don't guess. Then make its preview:

```bash
python3 scripts/gallery.py --include "<file>" --no-open
```

If they want to see everything, pass every artifact from this session:

```bash
python3 scripts/gallery.py --include "<file>" --include "<file>"
```

The script keeps the newest 24, makes previews, writes a gallery page, opens it, and prints the numbered list and the path to `manifest.json`. If the page does not open, show the numbered list in chat. Preview tools in your host are fine too.

Ask which number to archive, and wait. Never choose for them, even if one candidate looks obvious or there is only one. If there is nothing to show, the script exits with code 3. Tell the member and stop.

**Create something new.** Ask what they made. Suggest one or two ways to show it from this table, and let them pick:

| Kind of work | What to show |
|---|---|
| App or website | The running interface, or a GIF of it being used |
| Renderer, generator or creative code | Something it rendered or generated |
| Data or analysis | The chart or result |
| Command-line tool | The thing it made or made possible, never the terminal |
| Hardware or physical build | A photo of the real thing |
| Backend, library or infrastructure | A real result it produced, such as a dashboard or a before and after |

Then run the work and capture the result. For a web app that's running, use:

```bash
python3 scripts/capture.py --url "http://localhost:3000" --out "<file>.png"
```

**Rules for every image:**

- It must be real output. No mock-ups, and no AI-generated image standing in for the work.
- Ask before running anything that changes data, spends money or calls live services. Use sample data where possible.
- Never archive code, terminal output or logs, as text or as a picture of them.
- If there's nothing visual to show, say so and suggest waiting until there is. Don't invent something to fill the space.

**If the work moves,** such as a spin, a transition or an animation, a still doesn't show it. Make a GIF:

1. Capture one full loop as numbered PNG frames, with the last frame leading straight back to the first. A video also works.
2. Run `scripts/make_gif.sh --frames "<folder>" --out "<file>.gif"`, or `--video "<file>"` in place of `--frames`. Add `--fps` and `--edge` (the long edge in pixels) to change the defaults of 20 and 480.
3. Open the GIF and check it moves and loops cleanly.

The archive takes GIFs up to 10 MB, 1200 pixels on the long edge and 300 frames.

## 4. Draft the note

If you used the gallery, read `manifest.json` to find the item's `source` and `preview`. Otherwise the image is both.

Write one note of at most 280 characters. Say what the thing does and why it was made, not just what's in the image. Use plain words, with no hashtags or marketing language.

## 5. Privacy check

Run `python3 scripts/scan.py "<source>"`. It skips images, so always look at the image yourself too.

Stop if either finds secrets, keys, passwords, personal data such as addresses or private messages, or anything marked confidential. In captures of software, look closely for real user data, API keys, internal URLs, file paths, usernames and browser tabs. Tell the member what you found and where. Do not archive it, and do not offer to blur or crop unless they ask.

## 6. Get approval

Show the member the image itself, not just its path, and the exact note. A GIF must play. Then ask both:

> Can you confirm AI assistance was used in the process of making this?
>
> Should I archive it?

Anything other than a clear yes to both means do not archive it. This applies to everything, including images they supply. If they change the note, show it again.

## 7. Archive

```bash
scripts/post.sh --image "<image>" --note "<note>" --approved --ai-confirmed
```

Pass `--approved` and `--ai-confirmed` only after the member's yes to each in step 6.

## 8. Finish

Give the member the deposit URL. Then delete the temporary gallery folder named in the manifest path.

If the server returns an error, show its message. Do not retry a `429`, which means the daily limit is reached.

## Removing a deposit

Follow these steps only when the member asks to remove, delete or unarchive a deposit. Removal is permanent. The image and note are deleted and can't be restored. If it's the newest deposit, the next deposit takes its number. Otherwise the number stays empty. A member can only remove their own deposits.

1. Get the deposit's number from the member, such as No. 0012 or the end of its link. Don't guess it.
2. Run `scripts/post.sh --show <number>`. Show the member the number, date, note and link.
3. Warn them, in these words:

   > Removing a deposit is permanent and can't be undone. Check that this is the right number before you go on. To confirm, reply with the number.

4. Wait. Go on only if they reply with that same number. Anything else means do not remove it. If the number differs, start again from step 2.
5. Run `scripts/post.sh --remove <number> --approved`, then tell them it's gone.

Never remove more than one deposit per confirmation.
