---
name: explain-folder
description: Use when a large or unfamiliar folder needs explaining - what it is, which program keeps it, why it is big and whether that is normal.
---

# Explain a folder

Work from what the scan shows, then say plainly how sure you are.

1. **Inspect it.** Call `inspect_path` with the folder. Note its space and share of the drive, when it was last written, its attributes, its largest entries and the types of file inside it.

2. **Read the path.** Most folders say who owns them:
   - `Program Files`, `Program Files (x86)`: installed programs, one folder per vendor or program.
   - `ProgramData\<Vendor>`, `Users\<name>\AppData\Local\<Vendor>\<Program>`, `AppData\Roaming\<Vendor>`: a program's data and caches.
   - `AppData\Local\Temp`, `Windows\Temp`: temporary files.
   - `AppData\Local\Packages\<Publisher.App_id>`: a Store app's data.
   - `node_modules`, `.git`, `target`, `bin`, `obj`, `.gradle`, `.nuget`: development tools and build output.
   - `AppData\Local\Docker` or a large `ext4.vhdx`: the virtual disk of Docker or a WSL distribution.

3. **Read what is inside.** The types inside tell you what it holds: `vhdx`, `vmdk` and `iso` are disk images; `pack` files are git history; `log` files are logs; `tmp` files are temporary; `mp4`, `mkv` and `mov` are video; `pst` and `ost` are mail; `msi` and `exe` in a cache are installers kept for repairs.

4. **Confirm.** Call `browse` on the folder, and a level further down where the space is, until the large entries make sense.

5. **Say what it is.** In a sentence or two, give:
   - what it is and which program keeps it, with how sure you are;
   - why it is big;
   - whether it is normal and whether the program would rebuild it if it were gone.

   If the path, contents and age don't add up to an answer, say you cannot identify it, give what you do know (its size, age and the types inside), and don't name an owner you are guessing.
