---
name: find-duplicates
description: Use when the user asks about duplicate files, or large media, disk images or archives may be stored more than once.
---

# Find duplicates

Duplicates are found by content, not by name: two files count as the same only when every byte matches. Use the `dca` MCP tools; never guess that files are copies from their names or sizes.

1. **Make sure there is a scan.** If `get_overview` fails, scan first (`scan_volume`, then `get_scan_status` until done).

2. **Search.** Call `find_duplicates` with the drive. Narrow it with `path` to a folder (for example `Users\mark`) when the user cares about one place, and leave `min_bytes` at its default of 1 MB unless they ask about small files. It reads file contents, so it can take a while: it stops after `max_seconds` (20 by default). If `complete` is false, say how many size groups were left unchecked (`unchecked_groups`) and offer to search again with more time or a narrower folder.
   - The copies programs keep in a profile are left out: AppData, the profile's dot folders (`.vscode`, `.nuget`) and `node_modules`. Those are an app's own files, such as old extension versions, and go away when the old versions are cleaned up (see `find_known_junk`), not by removing one copy. Set `include_app_folders` only when the user asks about them; a `path` inside one of them is always searched.

3. **Present the groups,** largest `recoverable_bytes` first: for each, the size of one copy, how many copies (`copies`), where they are, and what keeping one would give back. A group lists at most `files_per_group` copies (10 by default) and counts the rest in `more_files`; say how many more there are rather than asking for them all. Give the total `recoverable_bytes`. Say how many files could not be read (`skipped`); they were left out.

4. **Suggest which copy to keep,** and say why, but leave the choice to the user:
   - keep the copy inside a library folder (Documents, Pictures, Videos, Music) or a project over one in Downloads, Desktop or a temporary folder;
   - between two copies in similar places, keep the one with the shorter, clearer path;
   - copies made on purpose, such as a backup on another folder tree, may be wanted: ask rather than assume;
   - files that are identical because a program needs them in two places (an app's own folders) are left alone.

5. **Remove extra copies only when the user asks.** Once the user has said which copy of each group to keep, recycle the copies the user chose to remove, and only those: call `create_plan` with each as `recycle` (never `delete`; a duplicate is not a cache), then follow the plan steps of the `disk-cleanup` skill: show the dry run, ask, and call `execute_plan` only after they say yes. If a copy is refused, tell the user why rather than trying another way.
