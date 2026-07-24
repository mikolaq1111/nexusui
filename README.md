# NexusUI

> A beautiful, modular Luau UI library for Roblox — works via `gethui()` / `CoreGui`, loaded remotely from GitHub.

---

## Table of Contents

- [Project Structure](#project-structure)
- [Step 1 — Create a GitHub Repository](#step-1--create-a-github-repository)
- [Step 2 — Push the Source Code](#step-2--push-the-source-code)
- [Step 3 — Set the Raw Base URL](#step-3--set-the-raw-base-url)
- [Step 4 — Verify Raw URLs](#step-4--verify-raw-urls)
- [Step 5 — Execute in Roblox](#step-5--execute-in-roblox)
- [How Module Loading Works](#how-module-loading-works)
- [Persistent Config](#persistent-config)
- [Keybinds](#keybinds)
- [Customising the Theme](#customising-the-theme)
- [Adding New Components](#adding-new-components)
- [Troubleshooting](#troubleshooting)

---

## Project Structure

```
libsc/
├── README.md
│
├── ui-library/
│   ├── theme.lua          ← Design tokens (colours, fonts, corner radii, tweens)
│   ├── components.lua     ← All UI widget constructors
│   └── init.lua           ← Library façade — Library.new(), secure parent selection
│
├── plugin-libray/
│   ├── tween.lua          ← Animation helpers (play, sequence, pulse, shake …)
│   ├── drag.lua           ← Drag-and-drop + resize handle system
│   ├── config.lua         ← JSON persistence via writefile / readfile
│   └── init.lua           ← Assembles Tween + Drag + Config into one Plugins table
│
└── script/
    └── main.lua           ← Bootstrap: fetches all modules, builds the demo menu
```

---

## Step 1 — Create a GitHub Repository

1. Go to [github.com/new](https://github.com/new).
2. Fill in:
   - **Repository name** — e.g. `nexusui` (keep it short, no spaces)
   - **Visibility** — **Public** *(required so Roblox can fetch raw files without authentication)*
3. Leave *"Add a README"* unchecked (we supply our own).
4. Click **Create repository**.

---

## Step 2 — Push the Source Code

### Option A — Git CLI (recommended)

```bash
# Inside the libsc/ project directory
git init
git add .
git commit -m "feat: initial NexusUI source"

# Replace YOUR_USERNAME and YOUR_REPO with your actual values
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### Option B — GitHub Desktop

1. Open GitHub Desktop → **File → Add Local Repository** → select the `libsc/` folder.
2. Commit all files with a message such as `"Initial commit"`.
3. Click **Publish repository** (make sure *"Keep this code private"* is **unchecked**).

### Option C — Web Upload (no Git needed)

1. On your new repository page click **Add file → Upload files**.
2. Drag the entire folder contents (all `.lua` files keeping the folder hierarchy intact).
3. Click **Commit changes**.

---

## Step 3 — Set the Raw Base URL

After the push, your raw base URL will be:

```
https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/
```

You must set this value in **two files**:

### `script/main.lua` — line 18

```lua
-- BEFORE
local RAW_BASE = "https://raw.githubusercontent.com/OWNER/REPO/main/"

-- AFTER (example)
local RAW_BASE = "https://raw.githubusercontent.com/john/nexusui/main/"
```

### `plugin-libray/init.lua` — line 23

```lua
-- BEFORE
local RAW_BASE = "https://raw.githubusercontent.com/OWNER/REPO/main/plugin-libray/"

-- AFTER (example)
local RAW_BASE = "https://raw.githubusercontent.com/john/nexusui/main/plugin-libray/"
```

After editing, commit and push again:

```bash
git add script/main.lua plugin-libray/init.lua
git commit -m "fix: set correct RAW_BASE URLs"
git push
```

---

## Step 4 — Verify Raw URLs

Open each URL below in your browser (substituting your details).  
You should see **raw Luau source**, not a GitHub HTML page.

| File | Expected URL |
|---|---|
| `script/main.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/script/main.lua` |
| `ui-library/theme.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/ui-library/theme.lua` |
| `ui-library/components.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/ui-library/components.lua` |
| `plugin-libray/tween.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/plugin-libray/tween.lua` |
| `plugin-libray/drag.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/plugin-libray/drag.lua` |
| `plugin-libray/config.lua` | `https://raw.githubusercontent.com/YOU/REPO/main/plugin-libray/config.lua` |

> **If you see a 404:** the file path in the URL doesn't match the actual path in the repo.  
> GitHub paths are **case-sensitive** — `UI-Library` ≠ `ui-library`.

---

## Step 5 — Execute in Roblox

### From an executor (Synapse X, KRNL, Script-Ware, etc.)

Paste and run the following one-liner.  
The executor downloads `main.lua`, which then fetches every other module automatically.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/script/main.lua"))()
```

### From a LocalScript in Studio (Rojo / plain Studio)

```lua
-- Place this inside a LocalScript under StarterPlayerScripts
local Library    = require(script.Parent["ui-library"])         -- adjust path
local Plugins    = require(script.Parent["plugin-libray"])
local ui         = Library.new()
ui:SetPlugins(Plugins)
-- ... build your menu ...
```

### Toggle the menu

Press **`RightShift`** (configurable via `TOGGLE_KEY` at the top of `main.lua`).

---

## How Module Loading Works

```
Executor runs main.lua
  └─ game:HttpGet(RAW_BASE .. "ui-library/theme.lua")      → Theme table
  └─ game:HttpGet(RAW_BASE .. "ui-library/components.lua") → Components table
  └─ game:HttpGet(RAW_BASE .. "plugin-libray/tween.lua")   → Tween table
  └─ game:HttpGet(RAW_BASE .. "plugin-libray/drag.lua")    → Drag table
  └─ game:HttpGet(RAW_BASE .. "plugin-libray/config.lua")  → Config class
  └─ Library.new() → ScreenGui created under gethui()/CoreGui/PlayerGui
  └─ ui:CreateWindow(...)  → Window built from Components + Theme
```

Each `loadstring()` call compiles the fetched Lua source in a sandboxed chunk.  
No files are written to disk during loading — only the config system writes
to `nexus/nexus_settings.json` when you explicitly save.

---

## Persistent Config

Settings are saved in the executor's workspace folder at:

```
nexus/nexus_settings.json
```

The file is created automatically on first save.  
You can change the path by editing `CONFIG_PATH` in `script/main.lua`:

```lua
local CONFIG_PATH = "nexus/nexus_settings.json"
```

**Saved values:** aimbot state, aim smoothness, FOV, ESP toggles, ESP distance,
watermark, FPS unlock, UI theme, display name, and window position.

Auto-save runs every **60 seconds** while the menu is open, and also flushes
on `CharacterRemoving` to prevent data loss on respawn.

---

## Keybinds

| Key | Action |
|---|---|
| `RightShift` | Show / hide the entire menu |
| Drag title bar | Move window freely on screen |
| Click `–` button | Minimise / restore window |
| Click `✕` button | Close and destroy the window |

Change the toggle key at the top of `script/main.lua`:

```lua
local TOGGLE_KEY = Enum.KeyCode.RightShift   -- change to any KeyCode
```

---

## Customising the Theme

All colours, sizes, and animation speeds live in `ui-library/theme.lua`.  
To override individual tokens without editing the source file, pass a partial
table into `Library.new()`:

```lua
local ui = Library.new({
    Accent     = Color3.fromRGB(255, 80, 100),   -- crimson accent
    Background = Color3.fromRGB(10, 5, 5),
    -- all other tokens fall through to defaults
})
```

---

## Adding New Components

1. Open `ui-library/components.lua`.
2. Add a new function following the existing pattern:

```lua
function Components.CreateMyWidget(parent, options, theme, plugins)
    options = options or {}
    -- build GuiObjects ...
    local handle = {}
    handle.Instance = rootFrame
    function handle:Set(v) ... end
    function handle:Get() return ... end
    function handle:Destroy() rootFrame:Destroy() end
    return handle
end
```

3. Expose it in `ui-library/init.lua` by adding one line inside the component
   proxy loop:

```lua
-- Add "CreateMyWidget" to the list:
for _, name in ipairs({
    "CreateWindow", "CreateButton", ..., "CreateMyWidget"
}) do
```

4. Commit and push — no other files need to change.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `HTTP 404` on load | Wrong `RAW_BASE` URL or file path mismatch | Double-check Step 3 & 4; paths are case-sensitive |
| `attempt to call nil` on `gethui` | Executor doesn't expose `gethui` | The library automatically falls back to `CoreGui` — no action needed |
| Menu appears behind game UI | `DisplayOrder` too low | Increase `screenGui.DisplayOrder` in `ui-library/init.lua` (default: 999) |
| Config not saving | Executor doesn't support `writefile` | Config operations silently no-op; all other features still work |
| Window spawns off-screen | Saved position from different resolution | Delete `nexus/nexus_settings.json` in the executor workspace |
| Changes not reflecting after push | GitHub CDN caches raw files ~5 min | Wait a few minutes or append `?ts=<timestamp>` to the URL during development |

---

> Made with ❤️ using NexusUI — a Luau modal system for Roblox.
