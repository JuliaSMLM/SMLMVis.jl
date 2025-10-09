# Using SMLMVis Interactive Viewer on Remote/Headless Systems

## Problem

On remote servers without a display (no X11, no OpenGL), GLMakie fails to precompile/run because it requires:
- OpenGL graphics drivers
- A display (`:0.0` or `DISPLAY` environment variable)
- Desktop windowing system

## Solution: WGLMakie (WebGL Backend)

**WGLMakie** is designed specifically for headless/remote systems:
- Renders using WebGL (browser-based)
- Serves plots via HTTP (default: `http://localhost:9284`)
- No display or OpenGL required
- Works perfectly over SSH

## Setup

### 1. Install WGLMakie

```julia
using Pkg
Pkg.activate("path/to/SMLMVis")
Pkg.add("WGLMakie")
```

### 2. Use WGLMakie Test Script

```bash
julia --project=. dev/test_viewer_wglmakie.jl
```

### 3. Access via SSH Port Forwarding

**On your laptop/desktop:**
```bash
ssh -L 9284:localhost:9284 username@remote-server.edu
```

This forwards port 9284 from the server to your local machine.

**Then open in your browser:**
```
http://localhost:9284
```

## Differences: GLMakie vs WGLMakie

| Feature | GLMakie | WGLMakie |
|---------|---------|----------|
| **Display** | Desktop window | Web browser |
| **Graphics** | OpenGL (GPU) | WebGL (browser) |
| **Remote** | Requires X forwarding | Works via SSH tunnel |
| **Performance** | Fast | Good |
| **Use case** | Local machine with GUI | Remote/headless systems |

## Package Fixes Applied

### 1. Fixed SMLMData Version Constraint

**Before:** `SMLMData = "0.2.3"` (pinned to exact version)
**After:** `SMLMData = "0.2"` (allows 0.2.x updates)

Now you can upgrade:
```julia
using Pkg
Pkg.update("SMLMData")
```

### 2. Moved GLMakie to Weak Dependencies

**Before:** GLMakie in `[deps]` (required, causes precompile failures)
**After:** GLMakie in `[weakdeps]` (optional, loaded via extension)

Benefits:
- SMLMVis works without GLMakie
- Install only what you need (GLMakie OR WGLMakie)
- No precompile errors on headless systems

## Current Configuration

```toml
[deps]
# Core dependencies only
Statistics = "..."
Images = "..."
...

[weakdeps]
GLMakie = "..."      # Optional - for local GUI
WGLMakie = "..."     # Optional - for remote/browser

[extensions]
SMLMVisGLMakieExt = "GLMakie"      # Loads if GLMakie installed
SMLMVisWGLMakieExt = "WGLMakie"    # Loads if WGLMakie installed
```

## Testing Remote Workflow

### Full Example

**1. On remote server:**
```bash
cd /home/kalidke/julia_shared_dev/SMLMVis
julia --project=.
```

**2. In Julia:**
```julia
using Pkg
Pkg.add("WGLMakie")  # First time only

include("dev/test_viewer_wglmakie.jl")
```

**3. On your laptop:**
```bash
# In a NEW terminal
ssh -L 9284:localhost:9284 kalidke@remote-server
```

**4. In your browser:**
```
http://localhost:9284
```

You should see the interactive viewer in your browser!

**5. Interact:**
- Use mouse to drag slider
- Press `n`/`p` for next/previous slice
- Press `i`/`o` to zoom
- Close browser tab when done

**6. Stop server:**
- In Julia REPL: `Ctrl+C`

## Troubleshooting

### Port 9284 already in use

Change the port:
```julia
# WGLMakie uses environment variable
ENV["WEBIO_HTTP_PORT"] = "8080"
include("dev/test_viewer_wglmakie.jl")
```

Then use `ssh -L 8080:localhost:8080 ...`

### SSH tunnel not working

Verify tunnel is active:
```bash
# On laptop
netstat -an | grep 9284
# Should show LISTEN on 127.0.0.1:9284
```

### Browser shows blank page

- Check Julia is still running (not crashed)
- Check terminal for error messages
- Try refreshing browser
- Check firewall rules

### Precompilation still fails

Make sure GLMakie is NOT in main dependencies:
```julia
using Pkg
Pkg.rm("GLMakie")  # Remove if accidentally added
Pkg.add("WGLMakie")
```

## Alternative: CairoMakie for Static Plots

If you only need static images (no interaction), use CairoMakie:

```julia
using CairoMakie  # Already in dependencies
# Use for saving static images, not interactive viewing
```

CairoMakie works everywhere but doesn't support interactivity.

## Performance Tips

- **Browser choice:** Chrome/Edge faster than Firefox for WebGL
- **Network:** Local SSH faster than VPN
- **Data size:** 256×256×50 works well, 1024×1024×200 may be slower
- **Compression:** WGLMakie compresses data automatically

## Summary

✅ **SMLMData can now upgrade** (version constraint relaxed)
✅ **WGLMakie works on remote systems** (no display needed)
✅ **GLMakie is optional** (won't break headless systems)
✅ **Extensions load automatically** (based on what's installed)

For remote work: **Use WGLMakie**
For local work: **Use GLMakie** (faster, better performance)
