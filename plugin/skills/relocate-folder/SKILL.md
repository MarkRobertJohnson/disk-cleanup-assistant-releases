---
name: relocate-folder
description: Use when the user wants to move a large folder (an SDK, models, games, virtual machines, a cache) to another drive without breaking the programs that use it, or asks to free space on C: by moving things rather than deleting them.
---

# Relocate a folder

Relocating moves a folder to another drive and leaves a junction at its old path, so programs still find it where they always did. It frees space on the original drive once the plan is finished. Use the `dca` MCP tools; never move folders with shell commands.

1. **Find candidates.** Call `find_relocation_candidates` with the drive (after a scan). Present the largest first: size, what it is (`kind`), when it was last written, and its `note`. A candidate with `blocked` must not be moved: say why, in the tool's words, and suggest what the note or reason says instead (cleaning it, or the program's own setting). For a "Large folder" the catalog does not know, follow the `explain-folder` skill before suggesting it.

2. **Pick the drive.** Only the drives in `targets` can take a folder: fixed NTFS drives. Say how much each has free. Tell the user the drive must stay connected: if it is ever missing, the programs that use the folder stop working until it is back. Prefer a note's cleaner way when there is one (an environment variable such as `OLLAMA_MODELS`, or the program's own move feature, such as Steam's or Windows' Location tab); offer the relocation as the alternative.

3. **Ask the user to close the program first.** A relocation copies the folder and is refused while any program has files open in it; name the program from the candidate's kind or note.

4. **Plan it.** Call `create_plan` with each folder as `relocate` and its `to` drive. Show the dry run: the folder, its size, and where it moves (`to`), plus every refused item with its reason. Ask the user; only after they say yes, call `execute_plan` (their client then asks them to approve it once more).

5. **Report, and wait.** Say what moved. The original is kept as `<name>.dca-old` on the old drive, so no space is freed yet. Ask the user to open the program and check it works from the new place.

6. **Finish.** Only after the user says the program works, call `finish_plan`; their client asks them to approve deleting the old copies, which frees the space. If something is wrong instead, call `undo_plan`: it removes the junction and puts the original back.

Never work around a refusal or a blocked folder by moving the parent folder or the files inside it one by one.
