# Testing the Interactive Stack Viewer

## Quick Start

### 1. Install Dependencies

```bash
cd /home/kalidke/julia_shared_dev/SMLMVis
julia --project=.
```

In Julia REPL:
```julia
using Pkg
Pkg.instantiate()  # Install existing dependencies
Pkg.add("GLMakie") # Add GLMakie for interactive viewing
```

### 2. Run Quick Test

```julia
include("dev/test_viewer_quick.jl")
```

This will:
- Generate a 3D test stack (256×256×50) with gradients and spots
- Launch the interactive viewer
- Display keyboard controls

### 3. Use the Viewer

**Mouse:**
- Drag the slider to navigate Z-slices

**Keyboard:**
- `n` / `p` - Next / Previous slice
- `i` / `o` - Zoom in / out
- `q` - Show quit message (then close window)

**Window:**
- Use X button to close

## Test Suite

### Comprehensive Tests

```julia
include("dev/test_stack_viewer.jl")
```

This generates test data but doesn't auto-launch viewers (to avoid opening many windows). Uncomment the `stack_viewer()` calls to test specific cases:

1. **Test 1:** 2D gradient
2. **Test 2:** 3D spots
3. **Test 3:** 3D concentric rings
4. **Test 4:** 4D spots (warns about Phase 2)
5. **Test 5:** 4D traveling wave (warns about Phase 2)
6. **Test 6:** High dynamic range 16-bit data

### Manual Testing Checklist

- [ ] 2D data displays correctly
- [ ] 3D slider appears and works
- [ ] Keyboard navigation (n/p) works
- [ ] Zoom controls (i/o) work
- [ ] Window closes properly
- [ ] Data range extremes handled (very dark, very bright)
- [ ] Edge cases: first slice, last slice
- [ ] Large data (512×512×100) performs well

## Troubleshooting

### "GLMakie not found"
```julia
using Pkg
Pkg.add("GLMakie")
```

### "extension SMLMVisGLMakieExt did not load"
Make sure both SMLMVis and GLMakie are in the same environment:
```julia
Pkg.activate(".")
Pkg.status()  # Should show both packages
```

### Viewer window doesn't appear
- Check DISPLAY variable on Linux
- Try running with `-t 1` for single-threaded Julia
- Check GLMakie installation: `using GLMakie; scatter(rand(10))`

### Slow performance
- Reduce data size for testing
- Check that UInt8 conversion is working (should be fast)
- Monitor memory usage

### Window freezes
- This is a Phase 1 limitation
- Close window and restart
- Report issue for Phase 2 improvements

## Expected Output

When running `test_viewer_quick.jl`, you should see:

```
================================================================================
Testing SMLMVis Interactive Stack Viewer - Phase 1 MVP
================================================================================

[Test 1] Creating 3D test stack (256×256×50)...
Adding random spots...
  Data range: (0.0, 12.345)
  Data size: (256, 256, 50)

================================================================================
Launching Interactive Viewer...
================================================================================

KEYBOARD CONTROLS:
  n/p  - Navigate forward/backward through Z-slices
  i/o  - Zoom in/out
  q    - Quit viewer

You can also use the slider to navigate through slices.
================================================================================

Viewer launched successfully!
Close the window or press 'q' to exit.
```

Then a window should open showing the first slice of the test data.

## Performance Benchmarks

Expected performance on typical hardware:

| Operation | Time (256×256) | Time (512×512) |
|-----------|----------------|----------------|
| Initial load | <100ms | <200ms |
| Slice navigation | <50ms | <100ms |
| Zoom in/out | <10ms | <20ms |
| UInt8 conversion | <20ms | <50ms |

## What to Test

### Basic Functionality
1. Data loads and displays
2. Slider moves through slices correctly
3. Keyboard shortcuts work
4. Zoom centers properly
5. Window closes without error

### Edge Cases
1. Single slice (2D) - slider should not appear
2. Empty regions - should display as black
3. Very high/low values - clipping should work
4. All same value - should display as gray

### User Experience
1. Is the UI intuitive?
2. Are controls responsive?
3. Is help text clear enough?
4. Would you use this for real data?

## Feedback

After testing, please provide feedback on:
1. Bugs encountered
2. Confusing UI elements
3. Missing features (for Phase 2)
4. Performance issues
5. General usability

## Next: Phase 2 Features

Vote on priority:
- [ ] Log/sqrt contrast methods
- [ ] Per-slice stretch
- [ ] 4D time navigation
- [ ] Statistics panel
- [ ] Histogram display
- [ ] Mouse wheel scrolling
- [ ] Better zoom (pan support)

---

Happy testing! 🔬
