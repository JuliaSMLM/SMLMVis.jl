# test_stack_viewer.jl
# Interactive stack viewer test data generator
#
# IMPORTANT: WGLMakie requires Julia REPL, NOT script execution!
#
# Usage:
#   1. Run this script ONCE to generate test data:
#      julia> include("dev/test_stack_viewer.jl")
#
#   2. Then launch viewer in REPL:
#      julia> using WGLMakie
#      julia> stack_viewer(data_3d_spots)
#
# For GLMakie (requires DISPLAY/X11):
#   BACKEND=GL julia dev/test_stack_viewer.jl

using Pkg
Pkg.activate("dev")

# Smart backend detection
function detect_backend()
    # Auto-detect based on environment
    if Sys.islinux()
        # Default to WGLMakie on Linux (works in VSCode, Jupyter, etc.)
        println("⚠ Note: Using WGLMakie (for VSCode/Jupyter)")
        println("  Works in VSCode plot pane, Jupyter, Pluto")
        return "WGL"
    elseif Sys.iswindows() || Sys.isapple()
        return "GL"  # Desktop systems default to GLMakie
    else
        return "CAIRO"  # Unknown platform, use static rendering
    end
end

backend = detect_backend()
println("✓ Using backend: $(backend)Makie")

if backend == "WGL"
    using WGLMakie
    # Bonito will auto-configure when needed in REPL
elseif backend == "GL"
    using GLMakie
elseif backend == "CAIRO"
    # CairoMakie is already loaded as a strong dependency
    # It doesn't have an interactive viewer, but can save to files
    println("  Note: CairoMakie doesn't have interactive viewer")
    println("  Viewer will display but not be interactive")
end

using SMLMVis
using SMLMVis.Interact

println("✓ Using $(backend)Makie backend")

"""
Generate synthetic test data with various features for testing the viewer.
"""
function generate_test_stack(;
    width=256,
    height=256,
    nslices=50,
    nframes=10,
    ndims_out=3,
    pattern=:gradient
)
    if ndims_out == 2
        data = zeros(Float32, height, width)
        if pattern == :gradient
            for i in 1:height, j in 1:width
                data[i, j] = (i + j) / (height + width)
            end
        elseif pattern == :spots
            # Random spots
            for _ in 1:100
                x, y = rand(1:width), rand(1:height)
                r = 5
                for dy in -r:r, dx in -r:r
                    if dx^2 + dy^2 <= r^2
                        yi, xi = clamp(y + dy, 1, height), clamp(x + dx, 1, width)
                        data[yi, xi] += exp(-(dx^2 + dy^2) / (2 * 2^2))
                    end
                end
            end
        end
        return data

    elseif ndims_out == 3
        data = zeros(Float32, height, width, nslices)

        if pattern == :gradient
            # Z-gradient with some XY structure
            for z in 1:nslices
                for i in 1:height, j in 1:width
                    # Gradient in Z, with XY modulation
                    data[i, j, z] = (z / nslices) * (1 + 0.3 * sin(2π * i / height) * cos(2π * j / width))
                end
            end

        elseif pattern == :spots
            # Moving spots through Z
            n_spots = 50
            for spot in 1:n_spots
                # Random trajectory
                x0, y0 = rand(1:width), rand(1:height)
                z_center = rand(1:nslices)
                intensity = rand(1000:5000)

                for z in 1:nslices
                    # Spot appears/disappears based on Z
                    z_intensity = exp(-((z - z_center) / 10)^2)

                    # Add Gaussian spot
                    r = 3
                    for dy in -r:r, dx in -r:r
                        if dx^2 + dy^2 <= r^2
                            yi = clamp(y0 + dy, 1, height)
                            xi = clamp(x0 + dx, 1, width)
                            data[yi, xi, z] += intensity * z_intensity * exp(-(dx^2 + dy^2) / (2 * 1.5^2))
                        end
                    end
                end
            end

        elseif pattern == :rings
            # Concentric rings that change with Z
            cx, cy = width / 2, height / 2
            for z in 1:nslices
                phase = 2π * z / nslices
                for i in 1:height, j in 1:width
                    r = sqrt((j - cx)^2 + (i - cy)^2)
                    data[i, j, z] = (1 + sin(0.1 * r + phase)) / 2
                end
            end
        end

        # Add some noise
        data .+= 0.05 * randn(Float32, size(data))
        data .= max.(data, 0)

        return data

    elseif ndims_out == 4
        data = zeros(Float32, height, width, nslices, nframes)

        if pattern == :gradient
            # Z-gradient with time evolution
            for t in 1:nframes
                for z in 1:nslices
                    for i in 1:height, j in 1:width
                        # Evolving pattern
                        time_phase = 2π * t / nframes
                        data[i, j, z, t] = (z / nslices) * (1 + 0.3 * sin(2π * i / height + time_phase) * cos(2π * j / width))
                    end
                end
            end

        elseif pattern == :spots
            # Moving spots in Z and T
            n_spots = 30
            for spot in 1:n_spots
                # Random trajectory
                x_center = rand(1:width)
                y_center = rand(1:height)
                z_center = rand(1:nslices)
                t_center = rand(1:nframes)
                intensity = rand(1000:5000)

                for t in 1:nframes, z in 1:nslices
                    # Spot appears/disappears based on Z and T
                    z_intensity = exp(-((z - z_center) / 10)^2)
                    t_intensity = exp(-((t - t_center) / 3)^2)

                    # Add Gaussian spot
                    r = 3
                    for dy in -r:r, dx in -r:r
                        if dx^2 + dy^2 <= r^2
                            yi = clamp(y_center + dy, 1, height)
                            xi = clamp(x_center + dx, 1, width)
                            data[yi, xi, z, t] += intensity * z_intensity * t_intensity * exp(-(dx^2 + dy^2) / (2 * 1.5^2))
                        end
                    end
                end
            end

        elseif pattern == :wave
            # Traveling wave in Z and T
            for t in 1:nframes, z in 1:nslices
                phase_t = 2π * t / nframes
                phase_z = 2π * z / nslices
                for i in 1:height, j in 1:width
                    # 2D wave pattern
                    kx, ky = 3, 2
                    data[i, j, z, t] = (1 + sin(kx * 2π * i / height + phase_t) * cos(ky * 2π * j / width + phase_z)) / 2
                end
            end
        end

        # Add some noise
        data .+= 0.05 * randn(Float32, size(data))
        data .= max.(data, 0)

        return data
    end
end

# ============================================================================
# Test Cases
# ============================================================================

println("="^80)
println("SMLMVis Interactive Stack Viewer - Test Suite")
println("="^80)

# Test 1: 2D image
println("\n[Test 1] 2D Image - Gradient Pattern")
data_2d = generate_test_stack(width=512, height=512, ndims_out=2, pattern=:gradient)
println("  Generated: $(size(data_2d))")
println("  Range: $(extrema(data_2d))")
# stack_viewer(data_2d; title="Test 1: 2D Gradient")

# Test 2: 3D stack - Spots
println("\n[Test 2] 3D Stack - Moving Spots")
data_3d_spots = generate_test_stack(width=256, height=256, nslices=50, ndims_out=3, pattern=:spots)
println("  Generated: $(size(data_3d_spots))")
println("  Range: $(extrema(data_3d_spots))")
# stack_viewer(data_3d_spots;
#     title="Test 2: 3D Spots",
#     pixel_size=0.1,  # 100 nm pixels
#     z_step=0.2       # 200 nm z-steps
# )

# Test 3: 3D stack - Rings
println("\n[Test 3] 3D Stack - Concentric Rings")
data_3d_rings = generate_test_stack(width=256, height=256, nslices=50, ndims_out=3, pattern=:rings)
println("  Generated: $(size(data_3d_rings))")
println("  Range: $(extrema(data_3d_rings))")
# stack_viewer(data_3d_rings;
#     title="Test 3: 3D Rings",
#     contrast=:linear,
#     stretch=:global
# )

# Test 4: 4D stack - Spots moving in Z and T
println("\n[Test 4] 4D Stack - Spots in Z+T")
data_4d_spots = generate_test_stack(width=128, height=128, nslices=30, nframes=20, ndims_out=4, pattern=:spots)
println("  Generated: $(size(data_4d_spots))")
println("  Range: $(extrema(data_4d_spots))")
# stack_viewer(data_4d_spots;
#     title="Test 4: 4D Spots",
#     pixel_size=0.1,
#     z_step=0.2,
#     frame_interval=0.05,  # 50 ms per frame
#     contrast=:linear,
#     stretch=:global
# )

# Test 5: 4D stack - Traveling Wave
println("\n[Test 5] 4D Stack - Traveling Wave")
data_4d_wave = generate_test_stack(width=128, height=128, nslices=30, nframes=20, ndims_out=4, pattern=:wave)
println("  Generated: $(size(data_4d_wave))")
println("  Range: $(extrema(data_4d_wave))")
# stack_viewer(data_4d_wave;
#     title="Test 5: 4D Wave",
#     frame_interval=0.1,
#     show_stats=true,
#     show_histogram=false
# )

# Test 6: High dynamic range data
println("\n[Test 6] High Dynamic Range (16-bit simulation)")
data_float = generate_test_stack(width=256, height=256, nslices=40, ndims_out=3, pattern=:spots)
data_hdr = UInt16.(round.(clamp.(data_float .* 10000, 0, 65535)))  # Round and clamp to UInt16 range
println("  Generated: $(size(data_hdr)), $(eltype(data_hdr))")
println("  Range: $(extrema(data_hdr))")
# stack_viewer(data_hdr;
#     title="Test 6: HDR Data",
#     contrast=:log,  # Should auto-suggest log for HDR
#     clip=(0.01, 0.99)
# )

println("\n" * "="^80)
println("Test data generated successfully!")
println("="^80)

# Run a test interactively
# Default: Test 2 (3D spots)
# To change: Edit this line to test_num = 1, 3, 4, 5, or 6
test_num = 2

if test_num == 1
    println("\n→ Launching Test 1: 2D Gradient")
    fig = stack_viewer(data_2d; title="Test 1: 2D Gradient")

elseif test_num == 2
    println("\n→ Launching Test 2: 3D Spots (default)")
    println("  Calling stack_viewer..."); flush(stdout)
    fig = stack_viewer(data_3d_spots;
        title="Test 2: 3D Spots",
        pixel_size=0.1,
        z_step=0.2
    )
    println("  stack_viewer returned!"); flush(stdout)

elseif test_num == 3
    println("\n→ Launching Test 3: 3D Rings")
    fig = stack_viewer(data_3d_rings;
        title="Test 3: 3D Rings"
    )

elseif test_num == 4
    println("\n→ Launching Test 4: 4D Spots (Z+T)")
    println("  Note: 4D not yet implemented, showing first timepoint")
    fig = stack_viewer(data_4d_spots[:,:,:,1];
        title="Test 4: 4D Spots (t=1)"
    )

elseif test_num == 5
    println("\n→ Launching Test 5: 4D Wave (Z+T)")
    println("  Note: 4D not yet implemented, showing first timepoint")
    fig = stack_viewer(data_4d_wave[:,:,:,1];
        title="Test 5: 4D Wave (t=1)"
    )

elseif test_num == 6
    println("\n→ Launching Test 6: HDR Data")
    fig = stack_viewer(data_hdr;
        title="Test 6: HDR Data",
        clip=(0.01, 0.99)
    )

else
    println("\n✗ Invalid TEST=$test_num (use 1-6)")
    println("  Default: TEST=2 (3D Spots)")
    exit(1)
end

println("\n✓ Viewer created!")

# Display the figure
# In REPL: This will open in VSCode plot pane automatically
# In script: Skip display to avoid hanging
if isinteractive()
    println("  Interactive REPL detected - displaying figure...")
    display(fig)
    println("  ✓ Figure should appear in plot pane")
else
    println("  ⚠ Non-interactive script mode - skipping auto-display")
    println("  ")
    println("  To view the figure, use Julia REPL instead:")
    println("    julia> include(\"dev/test_stack_viewer.jl\")")
    println("    julia> fig  # Auto-displays in REPL")
    println("  ")
    println("  Figure stored in variable: fig")
end

if backend == "WGL" && isinteractive()
    # Only keep alive in interactive mode
    println("\n  WGLMakie server running")
    println("  Keeping script alive... Press Ctrl+C to exit")

    # Keep script alive to serve WGLMakie content
    try
        while true
            sleep(1)
        end
    catch e
        if isa(e, InterruptException)
            println("\n✓ Shutting down server...")
        else
            rethrow(e)
        end
    end
elseif backend == "WGL" && !isinteractive()
    println("\n✓ Script complete. Use include() from REPL to view figure.")
end
