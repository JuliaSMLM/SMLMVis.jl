# Product Requirements Document: Interactive Stack Viewer

## Overview

An interactive viewer for multidimensional image data (1D-4D) inspired by dipimage's `dipshow` functionality. Provides real-time slice navigation, contrast adjustment, and zoom control for scientific image visualization.

## Target Use Cases

- **2D+Z stacks**: Navigate through z-slices of 3D microscopy data
- **2D+Z+T**: Time series of 3D stacks (4D data)
- **Quick visualization**: Rapidly explore acquired image stacks
- **Remote viewing**: Web-based display for headless/server environments

## Core Requirements

### 1. Input Data Support

**Supported Dimensionalities:**
- 1D: Line plot visualization
- 2D: Single image display
- 3D: Stack with slider navigation (X × Y × Z)
- 4D: Stack with dual navigation (X × Y × Z × T)

**Data Types:**
- Input: Any numeric array (Int, Float, UInt8, UInt16, etc.)
- Internal: Convert to UInt8 for efficient rendering (especially for WGLMakie)
- Handle grayscale and RGB images

**Data Formats:**
- Julia arrays: `Array{T,N}` where N ∈ {1,2,3,4}
- Image types from Images.jl: `Gray`, `RGB`, etc.

### 2. Backend Selection

**Automatic Backend Detection:**
```julia
if display_available() && Sys.iswindows()
    use GLMakie  # Native OpenGL backend
else
    use WGLMakie  # WebGL backend for headless/remote
end
```

**Manual Override:**
```julia
stack_viewer(data; backend=:GLMakie)  # Force specific backend
stack_viewer(data; backend=:WGLMakie)
```

**Detection Logic:**
- Check `DISPLAY` environment variable (Unix/Linux)
- Check if running in Jupyter/Pluto notebook
- Check if Windows with available display
- Default to WGLMakie for safety on servers

### 3. Display Controls

#### Contrast/Intensity Adjustment

**Dropdown Menu: Contrast Method**
- Linear stretch (default)
- Logarithmic stretch
- Square root stretch
- Histogram equalization

**Dropdown Menu: Stretch Mode**
- Global: Use min/max across entire stack
- Per-slice: Recalculate min/max for current slice
- Manual: User-specified min/max values (via text boxes)

**Dropdown Menu: Percentile Clipping**
- None (0-100%)
- 0.1-99.9% (default, removes extreme outliers)
- 0.5-99.5%
- 1-99%
- 2-98%
- 5-95%
- Custom (user-specified)

**Manual Range Controls:**
- Text boxes: Min value / Max value
- Auto button: Reset to calculated range
- Apply button: Apply manual range
- Displayed in expanded stats panel

**Keyboard Shortcuts:**
- `c` = cycle through contrast methods (Linear → Log → Sqrt → Equalize → Linear)
- `s` = toggle stretch mode (Global ↔ Per-slice)

**Implementation:**
- Apply percentile clipping before stretch calculation
- Apply contrast stretch before UInt8 conversion
- Update in real-time when changing slices (per-slice mode)
- Cache global min/max on first load
- Smart defaults: detect high dynamic range data (>10000) → suggest log contrast

#### Zoom Control

**Dropdown Menu: Zoom Factor**
- Options: 0.25×, 0.5×, 1.0× (native), 2×, 4×, 8×, 16×
- Default: 1.0× (native pixel size)
- Use nearest-neighbor interpolation for integer zooms
- Use bilinear for fractional zooms

**Keyboard Shortcuts:**
- `i` = zoom in (next higher preset)
- `o` = zoom out (next lower preset)
- `1-9` = direct zoom preset selection (1=0.25×, 5=1.0×, 9=16×)
- `r` = reset to native (1.0×) and first slice

**Behavior:**
- Maintain center position when changing zoom
- Update window size to accommodate zoomed image
- Display current zoom level in window title and status bar
- Pan with click-and-drag when zoomed

#### Navigation Controls

**3D Navigation (Z-axis):**
- Slider: Interactive slider for slice selection
- Keyboard:
  - `n` = next slice (increment Z)
  - `p` = previous slice (decrement Z)
  - `↑/↓` or `←/→` = alternative Z navigation
  - `Home` = jump to first slice
  - `End` = jump to last slice
  - Mouse scroll = navigate Z-axis
- Display: "Slice X / N" indicator with physical position (if metadata available)

**4D Navigation (T-axis, time/channel):**
- Slider: Interactive slider for T-axis selection
- Keyboard:
  - `f` = forward in time (increment T)
  - `b` = backward in time (decrement T)
  - `↑/↓` = alternative T navigation (when focused on T slider)
- Display: "Frame X / N" indicator with elapsed time

**Playback Controls (4D only):**
- Spacebar: Play/pause auto-advance through T dimension
- `+/-`: Increase/decrease playback speed
- `l`: Toggle loop mode (wraparound at end)
- Speed options: 1, 5, 10, 30 fps (dropdown)
- Visual indicator: Play/pause button, current speed, elapsed time

**Wraparound Behavior:**
- Configurable: wrap to opposite end or stop at boundaries
- Default: stop at boundaries for Z, wrap for T during playback

### 4. User Interface Layout

#### Compact Mode (Default)
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Stack Viewer - mydata.tif                                          [▭][□][✕] ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║ Contrast: [Linear    ▾] Stretch: [Global ▾] Clip: [0.1-99.9% ▾] Zoom: [1×▾] ║
║ ┌─ Stats ────────────────────────────────────────────────────────────────┐   ║
║ │ Min: 0    Max: 4095    Mean: 856.3    Std: 234.1    [Show Histogram]  │   ║
║ └─────────────────────────────────────────────────────────────────────────┘   ║
╟───────────────────────────────────────────────────────────────────────────────╢
║                                                                               ║
║                                                                               ║
║                        ┌────────────────────────┐                            ║
║                        │                        │                            ║
║                        │                        │                            ║
║                        │   [Image Display]      │                            ║
║                        │     512 × 512          │                            ║
║                        │                        │                            ║
║                        │                        │                            ║
║                        └────────────────────────┘                            ║
║                                                                               ║
║                                                                               ║
╟───────────────────────────────────────────────────────────────────────────────╢
║ Z: [════●═══════════════════════════════════] Slice: 45/100  (450.0 μm)      ║
║ T: [════●═══════] Frame: 3/10  [▶ Play 10fps ▾]  Loop:[✓]  Elapsed: 0.30s   ║
╟───────────────────────────────────────────────────────────────────────────────╢
║ (256, 342, 45, 3) = 1247  │  h:Help  i/o:Zoom  n/p:Z±1  f/b:T±1  Space:Play ║
╚═══════════════════════════════════════════════════════════════════════════════╝
     └─ Cursor position & value  └─ Quick reference
```

#### Expanded Mode (with Histogram & Advanced Controls)
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║ Stack Viewer - mydata.tif                                          [▭][□][✕] ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║ Contrast: [Linear    ▾] Stretch: [Global ▾] Clip: [0.1-99.9% ▾] Zoom: [1×▾] ║
║ ┌─ Statistics & Histogram ───────────────────────────────────────────────┐   ║
║ │ Min: 0      Max: 4095     Mean: 856.3    Std: 234.1    [Hide]         │   ║
║ │                                                                         │   ║
║ │   ▂▄▆█▇▅▃▂▁                      Histogram                             │   ║
║ │  ▁▃▅▇███▇▅▃▂▁▁                 (Current Slice)                         │   ║
║ │ ▁▃▅▇██████▇▅▃▂▁▁                                                       │   ║
║ │ ────────────────────────────────────────────────────────               │   ║
║ │ 0            1024           2048           3072          4095          │   ║
║ │                                                                         │   ║
║ │ Manual Range: Min [    0] Max [4095]  [Auto]  [Apply]                 │   ║
║ └─────────────────────────────────────────────────────────────────────────┘   ║
╟───────────────────────────────────────────────────────────────────────────────╢
║                                                                               ║
║                        ┌────────────────────────┐                            ║
║                        │                        │                            ║
║                        │   [Image Display]      │                            ║
║                        │     512 × 512          │                            ║
║                        │                        │                            ║
║                        └────────────────────────┘                            ║
║                                                                               ║
╟───────────────────────────────────────────────────────────────────────────────╢
║ Z: [════●═══════════════════════════════════] Slice: 45/100  (450.0 μm)      ║
║ T: [════●═══════] Frame: 3/10  [▶ Play 10fps ▾]  Loop:[✓]  Elapsed: 0.30s   ║
╟───────────────────────────────────────────────────────────────────────────────╢
║ (256, 342, 45, 3) = 1247  │  h:Help  i/o:Zoom  n/p:Z±1  f/b:T±1  Space:Play ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

#### Help Overlay (Press 'h')
```
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           KEYBOARD SHORTCUTS                                  ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  NAVIGATION                    DISPLAY                    VIEW               ║
║  ───────────                   ───────                    ────               ║
║  n / p      Next/Prev Z-slice  c          Cycle contrast  i / o   Zoom in/out║
║  f / b      Forward/Back frame s          Toggle stretch  r       Reset view ║
║  Home / End First/Last slice   h          Toggle help     F11     Fullscreen ║
║  ← / →      (also Z-slice)     1-9        Zoom preset     Esc     Exit help  ║
║  ↑ / ↓      (also T-frame)                                                   ║
║                                                                               ║
║  PLAYBACK (4D data)            EXPORT                                        ║
║  ───────────────────           ──────                                        ║
║  Space      Play/Pause         Ctrl+S     Save slice                         ║
║  +/-        Faster/Slower      Ctrl+C     Copy to clipboard                  ║
║  l          Toggle loop        Ctrl+E     Export movie                       ║
║                                                                               ║
║  MOUSE                         OTHER                                         ║
║  ─────                         ─────                                         ║
║  Hover      Show pixel value   q          Quit viewer                        ║
║  Scroll     Navigate Z-axis    Ctrl+Q     Quit (confirm)                     ║
║  Click+Drag Pan image                                                        ║
║                                                                               ║
║                         Press 'h' or Esc to close                            ║
╚═══════════════════════════════════════════════════════════════════════════════╝
```

**Layout Details:**
- **Top Section**: Window title bar with standard controls
- **Control Panel**: Dropdowns for all major settings (contrast, stretch, clipping, zoom)
- **Stats Panel**: Collapsible panel showing image statistics and histogram
- **Main Display**: Centered image with responsive sizing
- **Navigation Panel**: Sliders for Z and T dimensions with playback controls
- **Status Bar**: Cursor position, pixel value, and quick keyboard reference
- **Help Overlay**: Full keyboard shortcut reference (toggled with 'h')

**Responsive Behavior:**
- Window resizes: Image scales to fit, maintains aspect ratio
- Stats panel: Collapsible to save space (Show/Hide button)
- Histogram: Optional, toggleable display
- Status bar: Always visible for quick reference

### 5. Display Information & Statistics

**Status Bar Information:**
- Cursor position: `(x, y, z, t)` coordinates
- Pixel value: Intensity value at cursor position
- Image dimensions: Width × Height × Depth × Frames
- Current slice/frame: "Slice 45/100 (450.0 μm)" (if physical scale available)

**Statistics Panel (Collapsible):**
- Min, Max, Mean, Standard Deviation (current slice or global)
- Toggle: Show/Hide histogram
- Update mode: Real-time (per-slice) or static (global)

**Histogram Display:**
- ASCII-art histogram (compact mode)
- Full graphical histogram (expanded mode)
- X-axis: Intensity values
- Y-axis: Frequency (log scale for wide dynamic range)
- Visual indicators for clipping percentiles

**Physical Scale Support:**
- If metadata available (pixel size, z-step):
  - Display positions in physical units (μm, nm)
  - Show scale bar on image
- Otherwise: Display in pixel units

### 6. Export & Clipboard Functionality

**Save Current Slice:**
- Shortcut: `Ctrl+S`
- Format: PNG (default), TIFF (preserves bit depth), JPEG
- Filename: Auto-generated with slice/frame info (e.g., `mydata_z045_t003.png`)
- Options: Save as displayed (with contrast) or raw data

**Copy to Clipboard:**
- Shortcut: `Ctrl+C`
- Copies current view as rendered (with contrast/zoom applied)
- Paste into other applications (ImageJ, PowerPoint, etc.)

**Export Movie/Animation:**
- Shortcut: `Ctrl+E`
- Options:
  - Dimension: Z-stack flythrough or T-series playback
  - Format: MP4, GIF, AVI
  - Frame rate: 1-60 fps
  - Quality: Low/Medium/High
- Progress bar during export

**Batch Export:**
- Save all slices as individual files
- Numbered sequence for ImageJ/FIJI import

### 7. Data Validation & Error Handling

**Input Validation:**
- Empty arrays: Display error message "No data to display"
- NaN/Inf values:
  - Option 1: Mask (show as black/white)
  - Option 2: Replace with 0 or clipped value
  - Warning message in status bar
- Very large arrays (>10GB):
  - Show warning dialog
  - Suggest subsampling or ROI selection
  - Proceed only with user confirmation

**Edge Cases:**
- Single slice (Z=1): Hide Z slider, show as 2D
- Single frame (T=1): Hide T controls
- 1D data: Show as line plot
- RGB data: Display directly, disable contrast controls (or convert to grayscale)

**Graceful Degradation:**
- Out of memory: Suggest reducing zoom or dimensions
- Backend unavailable: Fallback WGLMakie → GLMakie or error message
- Corrupted data: Display partial data with warning

### 8. Window Management & Preferences

**Window Size:**
- Default: 800×800 pixels
- Preset sizes: Small (512×512), Medium (768×768), Large (1024×1024)
- Custom size: User-resizable, maintains aspect ratio
- Fullscreen: `F11` toggle

**Persistence (Optional):**
- Remember last window size/position
- Save to config file: `~/.smlmvis/viewer_prefs.toml`
- Restore on next launch

**Multi-Window Support:**
- Allow multiple viewers simultaneously
- Each window independent
- Optional: Link navigation (future feature)

### 9. Accessibility Features

**Visual Accessibility:**
- High-contrast UI mode (optional theme)
- Adjustable font sizes for labels (Small/Medium/Large)
- Colorblind-friendly colormaps (perceptually uniform)
- Clear visual feedback for all interactions

**Keyboard-Centric Design:**
- All functions accessible via keyboard
- No mouse required for basic navigation
- Keyboard shortcuts discoverable via help overlay (`h`)

**Screen Reader Support (Future):**
- Descriptive labels for all UI elements
- Announce navigation changes (slice number, frame number)

### 10. Performance Requirements

**Efficiency:**
- UInt8 conversion for WGLMakie (8-bit rendering pipeline)
- Lazy loading: Only convert/display current slice
- Cache converted slices (LRU cache, max 50 slices)
- Smooth scrolling: <100ms slice update latency

**Memory Management:**
- For large 4D stacks (>2GB), load slices on-demand
- Clear cache when switching contrast modes
- Garbage collect old slices automatically

### 11. API Design

#### Primary Function

```julia
"""
    stack_viewer(data::AbstractArray;
                 backend::Symbol=:auto,
                 contrast::Symbol=:linear,
                 stretch::Symbol=:global,
                 clip::Tuple{Float64,Float64}=(0.001, 0.999),
                 zoom::Real=1.0,
                 title::String="Stack Viewer",
                 pixel_size::Union{Real,Nothing}=nothing,
                 z_step::Union{Real,Nothing}=nothing,
                 frame_interval::Union{Real,Nothing}=nothing,
                 colormap::Symbol=:gray,
                 show_stats::Bool=true,
                 show_histogram::Bool=false)

Launch an interactive viewer for multidimensional image data.

# Arguments
- `data`: 1D-4D array of image data
- `backend`: `:auto`, `:GLMakie`, or `:WGLMakie`
- `contrast`: `:linear`, `:log`, `:sqrt`, `:equalize`
- `stretch`: `:global` or `:slice`
- `clip`: Percentile clipping (min, max) as tuple, e.g., (0.001, 0.999)
- `zoom`: Initial zoom factor (0.25, 0.5, 1.0, 2, 4, 8, or 16)
- `title`: Window title
- `pixel_size`: Physical pixel size in μm (for scale bar)
- `z_step`: Z-slice spacing in μm (for physical coordinates)
- `frame_interval`: Time between frames in seconds (for 4D data)
- `colormap`: Colormap for display (`:gray`, `:viridis`, `:turbo`, etc.)
- `show_stats`: Show statistics panel on launch
- `show_histogram`: Show histogram on launch

# Keyboard Controls
**Navigation:**
- `n`/`p`, `↑`/`↓`, `←`/`→`: Navigate Z-axis (next/previous slice)
- `f`/`b`: Navigate T-axis (forward/backward frame)
- `Home`/`End`: Jump to first/last slice
- Mouse scroll: Navigate Z-axis

**Display:**
- `c`: Cycle contrast methods (Linear → Log → Sqrt → Equalize)
- `s`: Toggle stretch mode (Global ↔ Per-slice)
- `h`: Toggle help overlay

**View:**
- `i`/`o`: Zoom in/out
- `1-9`: Direct zoom preset
- `r`: Reset view (zoom=1.0, first slice)
- `F11`: Fullscreen toggle

**Playback (4D):**
- `Space`: Play/pause
- `+`/`-`: Faster/slower playback
- `l`: Toggle loop mode

**Export:**
- `Ctrl+S`: Save current slice
- `Ctrl+C`: Copy to clipboard
- `Ctrl+E`: Export movie

**Other:**
- `q`: Quit viewer
- `Esc`: Close help overlay

# Examples
```julia
# View 3D stack with default settings
using SMLMVis.Interact
data = rand(512, 512, 100)
stack_viewer(data)

# View with physical scale information
stack_viewer(data; pixel_size=0.1, z_step=0.2, title="SMLM Z-Stack")

# View 4D time series with log contrast
data_4d = rand(256, 256, 50, 20)
stack_viewer(data_4d;
    contrast=:log,
    stretch=:slice,
    frame_interval=0.1,
    show_histogram=true
)

# Force web backend for remote viewing
stack_viewer(data; backend=:WGLMakie)

# High dynamic range data with aggressive clipping
hdr_data = rand(UInt16, 512, 512, 100) .* 10000
stack_viewer(hdr_data;
    contrast=:log,
    clip=(0.01, 0.99),
    zoom=2.0
)
```

# Returns
- Nothing (opens interactive window)

# Notes
- For headless systems, automatically uses WGLMakie and serves on http://localhost:8888
- UInt8 conversion applied automatically for efficient rendering
- Large datasets (>10GB) trigger warning with option to proceed
"""
function stack_viewer(data::AbstractArray; kwargs...)
    # Implementation
end
```

#### SMLD Integration Function

```julia
"""
    locs_viewer(smld::SMLD;
                render_z_step::Real=0.1,
                render_options...)

Interactive viewer for SMLD localization data with Z-slice rendering.

Renders each Z-slice of localization data on-the-fly and displays in the
interactive stack viewer. Combines `render()` with `stack_viewer()`.

# Arguments
- `smld`: SMLD object containing localization data
- `render_z_step`: Z-spacing for rendered slices in μm
- `render_options...`: Additional options passed to `render()` (zoom, colormap, etc.)

# Examples
```julia
using SMLMVis.Interact
using SMLMData

# Load SMLD data
smld = load("data.h5")

# Interactive viewing with depth coloring
locs_viewer(smld; render_z_step=0.1, zoom=20, colormap=:turbo)
```
"""
function locs_viewer(smld::SMLD; kwargs...)
    # Implementation: slice SMLD by z, render each slice, display in stack_viewer
end
```

#### Convenience Aliases

```julia
# Already exported from Interact module
const view_stack = stack_viewer
const view_localizations = locs_viewer
```

### 12. Implementation Phases

**Phase 1: Core Viewer (MVP)**
- ⬜ Backend auto-detection (GLMakie vs WGLMakie)
- ⬜ 2D/3D display with Z-slider
- ⬜ Linear contrast with global stretch
- ⬜ Basic keyboard navigation (n/p for Z, i/o for zoom)
- ⬜ UInt8 conversion for efficient rendering
- ⬜ Basic status bar (slice number)
- ⬜ Window with title
- ⬜ Quit functionality (q key)

**Phase 2: Enhanced Contrast & Navigation**
- ⬜ All contrast methods (log, sqrt, equalize)
- ⬜ Per-slice stretching mode
- ⬜ Percentile clipping dropdown
- ⬜ Keyboard shortcuts (c=cycle contrast, s=toggle stretch)
- ⬜ 4D support (T-slider, f/b navigation)
- ⬜ Home/End navigation
- ⬜ Mouse scroll navigation
- ⬜ Arrow key navigation

**Phase 3: Display Information & Statistics**
- ⬜ Cursor position/value display in status bar
- ⬜ Statistics panel (min, max, mean, std)
- ⬜ Collapsible stats panel (show/hide)
- ⬜ Basic histogram display
- ⬜ Physical scale support (μm display if metadata provided)
- ⬜ Zoom factor display in UI

**Phase 4: Playback & Animation (4D)**
- ⬜ Playback controls (space=play/pause)
- ⬜ Speed control (+/- keys, fps dropdown)
- ⬜ Loop mode (l key)
- ⬜ Play/pause visual indicator
- ⬜ Elapsed time display
- ⬜ Frame rate display

**Phase 5: Export & Clipboard**
- ⬜ Save current slice (Ctrl+S)
- ⬜ Copy to clipboard (Ctrl+C)
- ⬜ Export movie (Ctrl+E)
- ⬜ Format selection (PNG, TIFF, JPEG)
- ⬜ Batch export (all slices)
- ⬜ Progress bar for long operations

**Phase 6: Advanced Features & Polish**
- ⬜ Manual min/max controls
- ⬜ Expanded histogram with controls
- ⬜ Zoom presets (1-9 keys)
- ⬜ Reset view (r key)
- ⬜ Fullscreen mode (F11)
- ⬜ Pan with click-and-drag
- ⬜ Help overlay (h key)
- ⬜ Window size presets
- ⬜ Colormap selection

**Phase 7: SMLD Integration & Data Handling**
- ⬜ `locs_viewer()` function for SMLD data
- ⬜ Data validation (NaN/Inf handling)
- ⬜ Large dataset warnings
- ⬜ Edge case handling (1D, single slice, RGB)
- ⬜ Smart default detection

**Phase 8: Preferences & Accessibility**
- ⬜ Config file for preferences
- ⬜ Remember window size/position
- ⬜ High-contrast UI theme
- ⬜ Font size adjustment
- ⬜ Colorblind-friendly defaults
- ⬜ Multi-window support

### 13. Technical Dependencies

**Required Packages:**
- GLMakie.jl: Native OpenGL backend
- WGLMakie.jl: WebGL backend for browsers
- Images.jl: Image data type support
- Statistics.jl: For min/max/quantile calculations
- FileIO.jl: Image file I/O for export
- ImageClipboard.jl: Clipboard integration (optional)
- VideoIO.jl: Movie export functionality (optional)

**Conditional Loading:**
- Use package extensions (Julia 1.9+) to avoid hard dependencies
- GLMakie and WGLMakie as optional extensions
- VideoIO as optional extension for movie export
- ImageClipboard as optional extension for clipboard

**Extension Structure:**
```julia
# Project.toml
[weakdeps]
GLMakie = "..."
WGLMakie = "..."
VideoIO = "..."

[extensions]
SMLMVisGLMakieExt = "GLMakie"
SMLMVisWGLMakieExt = "WGLMakie"
SMLMVisVideoExt = "VideoIO"
```

### 14. Testing Requirements

**Unit Tests:**
- Backend selection logic
- Contrast method correctness
- UInt8 conversion edge cases (NaN, Inf, negative)
- Dimension detection (1D vs 2D vs 3D vs 4D)

**Integration Tests:**
- Manual testing on different platforms:
  - Windows with display
  - Linux headless server
  - Jupyter notebook
- Test with various data types (UInt8, UInt16, Float32, Float64)

**Performance Tests:**
- Large stack loading (1024×1024×200)
- 4D time series (512×512×50×100)
- Zoom rendering speed

### 15. Documentation Requirements

**Docstrings:**
- Main `stack_viewer()` function with comprehensive examples
- `locs_viewer()` function for SMLD integration
- All keyword arguments explained with types and defaults
- Complete keyboard shortcut reference
- Return values and side effects documented

**User Guide:**
- **Getting Started Tutorial**: Basic 3D stack viewing
- **Dipimage Comparison**: Migration guide for dipshow users
- **4D Time Series Workflow**: Playback and export
- **SMLD Integration**: Using with localization data
- **Remote Viewing**: Headless server setup with WGLMakie
- **Performance Tips**: Large datasets, memory management
- **Troubleshooting**: Common issues and solutions

**Example Gallery:**
- Basic 2D/3D/4D viewing examples
- Custom contrast and clipping
- Physical scale display
- Export workflows (images, movies)
- SMLD rendering examples
- Remote/headless usage

**API Reference:**
- Complete function signatures
- All exported functions and aliases
- Extension points for customization

## Success Criteria

1. ✅ Successfully view 1D/2D/3D/4D data with smooth performance
2. ✅ Navigation latency <100ms for slice updates
3. ✅ Works in both GUI (GLMakie) and headless (WGLMakie) environments
4. ✅ Intuitive keyboard controls matching dipimage conventions (n/p, i/o, f/b)
5. ✅ Efficient memory usage for large datasets (>10GB warning, batching)
6. ✅ Clear, comprehensive documentation with examples
7. ✅ All contrast methods produce correct output (tested)
8. ✅ Export functionality works reliably (images, clipboard, movies)
9. ✅ SMLD integration functional for localization viewing
10. ✅ Accessible interface (keyboard-only operation, help overlay)

## Open Questions & Design Decisions

### Resolved:
- ✅ **Zoom shortcuts**: Use `i`/`o` (like dipshow), not `+`/`-` (requires shift)
- ✅ **Colormap support**: Include in API, default to grayscale, Phase 6 feature
- ✅ **4D display**: Use separate T slider + playback controls
- ✅ **Performance**: Skip GPU acceleration initially, revisit if needed

### Pending:
1. **Multi-channel data**: How to handle RGB/multi-channel in 3D/4D?
   - Option A: Convert to grayscale, warn user
   - Option B: Display each channel as separate "T" frames
   - Option C: Composite RGB with adjustable blending
   - **Decision needed**: Phase 7 feature, start with Option A

2. **Linked viewers**: Should multiple viewers be linkable for synchronized navigation?
   - Useful for multi-channel, before/after comparisons
   - **Decision**: Defer to Phase 8, non-MVP

3. **ROI selection**: Region-of-interest selection tool?
   - Useful for cropping, quantification
   - **Decision**: Post-MVP, separate feature

4. **Histogram binning**: How many bins for histogram?
   - Too few: poor resolution
   - Too many: slow, noisy
   - **Decision**: Adaptive (256 bins for UInt8, auto for others)

5. **Default clip percentiles**: 0.1-99.9% vs 1-99%?
   - 0.1-99.9%: More aggressive outlier removal
   - 1-99%: More conservative
   - **Decision**: 0.1-99.9% default, common for microscopy

## Deferred Features (Post-MVP / Future Versions)

**Advanced Visualization (v2.0):**
- Orthogonal view modes (XY/XZ/YZ simultaneous display)
- Maximum intensity projection (MIP)
- Volume rendering for 3D data
- Surface rendering (isosurfaces)

**Analysis Tools (v2.0):**
- ROI/line profile tools
- Measurement tools (distance, angle)
- Intensity quantification
- Multi-channel overlay/blending

**Collaboration Features (v2.0):**
- Linked viewers for synchronized navigation
- Annotation tools (arrows, text, scale bars)
- Session save/load (remember state)

**Performance Optimizations (as needed):**
- GPU-accelerated contrast calculations
- Downsample preview mode for huge datasets (>4096×4096)
- Tiled rendering for very large images
- Parallel slice loading

**Integration Features (v2.0):**
- Direct ImageJ/FIJI interop
- Import/export ROI formats
- Metadata preservation (OME-TIFF)
