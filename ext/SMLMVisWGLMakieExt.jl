module SMLMVisWGLMakieExt

# This is nearly identical to GLMakie extension, but uses WGLMakie (WebGL backend)
# Perfect for remote/headless systems - serves viewer via HTTP

using SMLMVis
using SMLMVis.Render
using SMLMVis.Interact
using SMLMVis.Animate
using WGLMakie
using WGLMakie.Makie: Figure, Axis, GridLayout, Label, Slider, Observable, on, events,
                      Keyboard, heatmap!, hidedecorations!, hidespines!, xlims!, ylims!,
                      autolimits!, DataAspect, @lift
using Images
using Statistics

# Include all the same utility functions and implementation
# The only difference is WGLMakie instead of GLMakie

# ============================================================================
# Utility Functions (identical to GLMakie version)
# ============================================================================

"""
Convert data to UInt8 for efficient display, applying contrast and clipping.
"""
function convert_to_uint8(data::AbstractArray{T};
                          clip::Tuple{Float64,Float64}=(0.001, 0.999),
                          contrast::Symbol=:linear) where T
    # Handle empty or invalid data
    if isempty(data) || all(isnan, data)
        return zeros(UInt8, size(data))
    end

    # Filter out NaN and Inf
    valid_data = filter(x -> isfinite(x), vec(data))
    if isempty(valid_data)
        return zeros(UInt8, size(data))
    end

    # Calculate percentile clipping bounds
    min_val = quantile(valid_data, clip[1])
    max_val = quantile(valid_data, clip[2])

    # Avoid division by zero
    if min_val == max_val
        return fill(UInt8(128), size(data))
    end

    # Create output array
    output = similar(data, UInt8)

    for i in eachindex(data)
        val = data[i]

        # Handle special values
        if !isfinite(val)
            output[i] = 0x00
            continue
        end

        # Clip to range
        val = clamp(val, min_val, max_val)

        # Normalize to 0-1
        normalized = (val - min_val) / (max_val - min_val)

        # Apply contrast method
        if contrast == :log
            normalized = log(1 + normalized) / log(2)
        elseif contrast == :sqrt
            normalized = sqrt(normalized)
        elseif contrast == :equalize
            normalized = normalized  # Placeholder
        end

        # Convert to UInt8
        output[i] = round(UInt8, clamp(normalized * 255, 0, 255))
    end

    return output
end

"""
Get current slice from multidimensional data.
"""
function get_slice(data::AbstractArray, z_idx::Int, t_idx::Int=1)
    ndims_data = ndims(data)

    if ndims_data == 1
        return reshape(data, :, 1)
    elseif ndims_data == 2
        return data
    elseif ndims_data == 3
        return data[:, :, z_idx]
    elseif ndims_data == 4
        return data[:, :, z_idx, t_idx]
    else
        error("Unsupported number of dimensions: $ndims_data")
    end
end

# ============================================================================
# Phase 1 MVP: Stack Viewer Implementation (WGLMakie version)
# ============================================================================

"""
    stack_viewer(data::AbstractArray; kwargs...)

Interactive viewer for multidimensional image stacks (1D-4D).
**WGLMakie (WebGL) version for remote/headless systems.**

Opens viewer in browser at http://localhost:9284

# Phase 1 MVP Features:
- 2D/3D display with Z-slider
- Linear contrast with global stretch
- Keyboard navigation (n/p for Z, i/o for zoom)
- UInt8 conversion for efficient rendering
- Basic status bar

# Arguments
- `data`: 1D-4D array of image data
- `backend`: `:auto`, `:GLMakie`, or `:WGLMakie` (this is WGLMakie)
- `contrast`: Contrast method (Phase 1: :linear only)
- `clip`: Percentile clipping tuple (default: (0.001, 0.999))
- `zoom`: Initial zoom factor (default: 1.0)
- `title`: Window title
- `pixel_size`: Physical pixel size in μm (optional)
- `z_step`: Z-slice spacing in μm (optional)

# Keyboard Controls (Phase 1):
- `n`/`p`: Next/previous slice
- `i`/`o`: Zoom in/out
- Close browser tab to quit
"""
function SMLMVis.Interact.stack_viewer(
    data::AbstractArray;
    backend::Symbol=:auto,
    contrast::Symbol=:linear,
    clip::Tuple{Float64,Float64}=(0.001, 0.999),
    zoom::Real=1.0,
    title::String="Stack Viewer",
    pixel_size::Union{Real,Nothing}=nothing,
    z_step::Union{Real,Nothing}=nothing,
    frame_interval::Union{Real,Nothing}=nothing
)
    # Validate data
    if isempty(data)
        error("Cannot display empty array")
    end

    ndims_data = ndims(data)
    if ndims_data > 4
        error("Unsupported number of dimensions: $ndims_data (max 4)")
    end

    # Get dimensions
    sz = size(data)
    height, width = sz[1], (ndims_data >= 2 ? sz[2] : 1)
    nslices = (ndims_data >= 3 ? sz[3] : 1)
    nframes = (ndims_data >= 4 ? sz[4] : 1)

    # Create figure
    fig = Figure(size=(800, 900))

    # Create main layout
    main_layout = fig[1, 1] = GridLayout()

    # Title
    Label(main_layout[1, 1], title, fontsize=16, halign=:left)

    # Main image axis
    ax = Axis(main_layout[2, 1],
             aspect=DataAspect(),
             title="",
             xlabel="",
             ylabel="")
    hidedecorations!(ax)
    hidespines!(ax)

    # Observables for reactive updates
    current_slice = Observable(1)
    current_frame = Observable(1)
    zoom_level = Observable(Float64(zoom))

    # Convert and display first slice
    function update_display()
        slice_data = get_slice(data, current_slice[], current_frame[])
        uint8_data = convert_to_uint8(slice_data; clip=clip, contrast=contrast)
        return uint8_data
    end

    # Initial image - get first slice data
    initial_img = update_display()

    # Create heatmap and store plot object for manual updates
    hm = heatmap!(ax, initial_img, colormap=:grays, colorrange=(0, 255))

    # Observable to track current slice for updates
    current_slice_obs = Observable(1)

    # Z-slider (only if 3D or 4D)
    sl_z = nothing
    if nslices > 1
        sl_z = Slider(main_layout[3, 1], range=1:nslices, startvalue=1)
        Label(main_layout[3, 2], @lift("Slice: $($(sl_z.value))/$nslices"), width=120)

        # Connect slider to update heatmap
        on(sl_z.value) do val
            current_slice[] = val
            hm[3][] = update_display()  # Update heatmap data (plot[3] contains z-values)
        end
    end

    # T-slider (only if 4D) - Phase 2 feature
    if nframes > 1
        @warn "4D data detected. Time navigation will be added in Phase 2"
    end

    # Status bar
    help_text = "n/p: Navigate  i/o: Zoom  Close browser tab to quit"
    Label(main_layout[4, 1:2], help_text, fontsize=12, halign=:left)

    # Keyboard controls
    on(events(fig).keyboardbutton) do event
        if event.action == Keyboard.press || event.action == Keyboard.repeat
            if event.key == Keyboard.n
                # Next slice
                if nslices > 1 && current_slice[] < nslices
                    current_slice[] += 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.p
                # Previous slice
                if nslices > 1 && current_slice[] > 1
                    current_slice[] -= 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.i
                # Zoom in
                new_zoom = zoom_level[] * 1.5
                zoom_level[] = min(new_zoom, 16.0)
                xlims = (width/2 - width/(2*zoom_level[]), width/2 + width/(2*zoom_level[]))
                ylims = (height/2 - height/(2*zoom_level[]), height/2 + height/(2*zoom_level[]))
                xlims!(ax, xlims...)
                ylims!(ax, ylims...)
            elseif event.key == Keyboard.o
                # Zoom out
                new_zoom = zoom_level[] / 1.5
                zoom_level[] = max(new_zoom, 0.25)
                if zoom_level[] <= 1.0
                    zoom_level[] = 1.0
                    autolimits!(ax)
                else
                    xlims = (width/2 - width/(2*zoom_level[]), width/2 + width/(2*zoom_level[]))
                    ylims = (height/2 - height/(2*zoom_level[]), height/2 + height/(2*zoom_level[]))
                    xlims!(ax, xlims...)
                    ylims!(ax, ylims...)
                end
            end
        end
    end

    # Return the figure without explicit display()
    # In REPL/IJulia/Pluto: The figure will auto-display
    # In scripts: Caller must explicitly call display(fig)
    # This avoids hanging in non-interactive contexts

    println("\n" * "="^80)
    println("WGLMakie Viewer Created")
    println("="^80)
    println("Figure ready for display")
    println("  In REPL: Will auto-display in plot pane")
    println("  In script: Call display(fig) manually")
    println("="^80 * "\n")

    return fig
end

# ============================================================================
# Phase 2+ features - not yet implemented
# ============================================================================
# These will be added in future phases:
# - locs_viewer: Interactive localization viewer
# - render_volume: 3D volume rendering
# - render_projection: Projection rendering
# - animate_time_series: Time series animations
# - animate_acquisition: Acquisition animations

end # module SMLMVisWGLMakieExt
