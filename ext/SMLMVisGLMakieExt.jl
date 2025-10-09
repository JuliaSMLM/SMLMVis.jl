module SMLMVisGLMakieExt

using SMLMVis
using SMLMVis.Render
using SMLMVis.Interact
using SMLMVis.Animate
using GLMakie
using GLMakie.Makie: Figure, Axis, GridLayout, Label, Slider, Observable, on, events,
                     Keyboard, heatmap!, hidedecorations!, hidespines!, xlims!, ylims!,
                     autolimits!, DataAspect, @lift
using Images
using Statistics

# ============================================================================
# Utility Functions
# ============================================================================

"""
Convert data to UInt8 for efficient display, applying contrast and clipping.
"""
function convert_to_uint8(data::AbstractArray{T};
                          clip::Tuple{Float64,Float64}=(0.001, 0.999),
                          clip_values::Union{Nothing,Tuple{Float64,Float64}}=nothing,
                          contrast::Symbol=:linear) where T
    # Handle empty or invalid data
    if isempty(data) || all(isnan, data)
        return zeros(UInt8, size(data))
    end

    # Determine clipping bounds
    min_val, max_val = if !isnothing(clip_values)
        # Use pre-computed min/max values
        clip_values
    else
        # Calculate percentile clipping bounds
        valid_data = filter(x -> isfinite(x), vec(data))
        if isempty(valid_data)
            return zeros(UInt8, size(data))
        end
        (quantile(valid_data, clip[1]), quantile(valid_data, clip[2]))
    end

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
            # Simple histogram equalization (approximate)
            # For full implementation, would need binning
            normalized = normalized  # Placeholder
        end
        # :linear is identity

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
# Phase 1 MVP: Stack Viewer Implementation
# ============================================================================

"""
    _stack_viewer_impl(data::AbstractArray; kwargs...)

GLMakie implementation of the interactive stack viewer.

This function is registered with SMLMVis.Interact and called via the main
stack_viewer() dispatch system. Not intended to be called directly.

# Phase 1 MVP Features:
- 2D/3D display with Z-slider
- Linear contrast with global stretch
- Keyboard navigation (n/p for Z, i/o for zoom, q to quit)
- UInt8 conversion for efficient rendering
- Basic status bar

# Arguments
- `data`: 1D-4D array of image data
- `contrast`: Contrast method (Phase 1: :linear only)
- `clip`: Percentile clipping tuple (default: (0.001, 0.999))
- `zoom`: Initial zoom factor (default: 1.0)
- `title`: Window title
- `pixel_size`: Physical pixel size in μm (optional)
- `z_step`: Z-slice spacing in μm (optional)

# Keyboard Controls (Phase 1):
- `n`/`p`: Next/previous slice
- `i`/`o`: Zoom in/out
- `q`: Quit viewer
"""
function _stack_viewer_impl(
    data::AbstractArray;
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
    current_contrast = Observable(contrast)  # Phase 2: Dynamic contrast
    current_stretch = Observable(:global)     # Phase 2: :global or :slice

    # Cache for global contrast values (computed once)
    global_clip_values = Ref{Union{Nothing, Tuple{Float64,Float64}}}(nothing)

    # Convert and display current slice with current settings
    function update_display()
        slice_data = get_slice(data, current_slice[], current_frame[])

        # Determine clip values based on stretch mode
        clip_vals = nothing
        if current_stretch[] == :slice
            # Per-slice stretching: recalculate percentiles for this slice
            valid_data = filter(isfinite, vec(slice_data))
            if !isempty(valid_data)
                min_clip = quantile(valid_data, clip[1])
                max_clip = quantile(valid_data, clip[2])
                clip_vals = (min_clip, max_clip)
            end
        else
            # Global stretching: use cached values
            if isnothing(global_clip_values[])
                # Calculate once for all slices
                all_valid = filter(isfinite, vec(data))
                if !isempty(all_valid)
                    min_clip = quantile(all_valid, clip[1])
                    max_clip = quantile(all_valid, clip[2])
                    global_clip_values[] = (min_clip, max_clip)
                    clip_vals = global_clip_values[]
                end
            else
                clip_vals = global_clip_values[]
            end
        end

        uint8_data = convert_to_uint8(slice_data; clip=clip, clip_values=clip_vals, contrast=current_contrast[])
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

        # Connect slider to observable
        on(sl_z.value) do val
            current_slice[] = val
            hm[3][] = update_display()  # Update heatmap data
        end
    end

    # T-slider (only if 4D)
    sl_t = nothing
    status_row = 4
    if nframes > 1
        sl_t = Slider(main_layout[4, 1], range=1:nframes, startvalue=1)
        Label(main_layout[4, 2], @lift("Frame: $($(sl_t.value))/$nframes"), width=120)

        # Connect slider to update heatmap
        on(sl_t.value) do val
            current_frame[] = val
            hm[3][] = update_display()  # Update heatmap data
        end
        status_row = 5
    end

    # Status bar with dynamic mode display
    status_text = @lift("Contrast: $($(current_contrast))  Stretch: $($(current_stretch))  |  n/p/↑↓: Navigate  f/b: Time  i/o: Zoom  c: Contrast  s: Stretch  q: Quit")
    Label(main_layout[status_row, 1:2], status_text, fontsize=12, halign=:left)

    # Mouse scroll navigation for Z-axis
    on(events(fig).scroll) do (dx, dy)
        if nslices > 1
            if dy > 0  # Scroll up - previous slice
                if current_slice[] > 1
                    current_slice[] -= 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()
                end
            elseif dy < 0  # Scroll down - next slice
                if current_slice[] < nslices
                    current_slice[] += 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()
                end
            end
        end
    end

    # Keyboard controls
    on(events(fig).keyboardbutton) do event
        if event.action == Keyboard.press || event.action == Keyboard.repeat
            if event.key == Keyboard.n || event.key == Keyboard.down
                # Next slice (n or Down arrow)
                if nslices > 1 && current_slice[] < nslices
                    current_slice[] += 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.p || event.key == Keyboard.up
                # Previous slice (p or Up arrow)
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
                # Update axis limits (approximate zoom)
                xlims = (width/2 - width/(2*zoom_level[]), width/2 + width/(2*zoom_level[]))
                ylims = (height/2 - height/(2*zoom_level[]), height/2 + height/(2*zoom_level[]))
                xlims!(ax, xlims...)
                ylims!(ax, ylims...)
            elseif event.key == Keyboard.o
                # Zoom out
                new_zoom = zoom_level[] / 1.5
                zoom_level[] = max(new_zoom, 0.25)
                # Reset to full view if zoomed out enough
                if zoom_level[] <= 1.0
                    zoom_level[] = 1.0
                    autolimits!(ax)
                else
                    xlims = (width/2 - width/(2*zoom_level[]), width/2 + width/(2*zoom_level[]))
                    ylims = (height/2 - height/(2*zoom_level[]), height/2 + height/(2*zoom_level[]))
                    xlims!(ax, xlims...)
                    ylims!(ax, ylims...)
                end
            elseif event.key == Keyboard.home
                # Jump to first slice
                if nslices > 1 && current_slice[] != 1
                    current_slice[] = 1
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard._end
                # Jump to last slice
                if nslices > 1 && current_slice[] != nslices
                    current_slice[] = nslices
                    if !isnothing(sl_z)
                        sl_z.value[] = current_slice[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.c
                # Cycle contrast method: linear → log → sqrt → equalize → linear
                contrast_methods = [:linear, :log, :sqrt, :equalize]
                current_idx = findfirst(==(current_contrast[]), contrast_methods)
                next_idx = current_idx == length(contrast_methods) ? 1 : current_idx + 1
                current_contrast[] = contrast_methods[next_idx]
                hm[3][] = update_display()  # Update display with new contrast
            elseif event.key == Keyboard.s
                # Toggle stretch mode: global ↔ slice
                if current_stretch[] == :global
                    current_stretch[] = :slice
                else
                    current_stretch[] = :global
                end
                hm[3][] = update_display()  # Update display with new stretch mode
            elseif event.key == Keyboard.f
                # Forward in time (next frame)
                if nframes > 1 && current_frame[] < nframes
                    current_frame[] += 1
                    if !isnothing(sl_t)
                        sl_t.value[] = current_frame[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.b
                # Backward in time (previous frame)
                if nframes > 1 && current_frame[] > 1
                    current_frame[] -= 1
                    if !isnothing(sl_t)
                        sl_t.value[] = current_frame[]
                    end
                    hm[3][] = update_display()  # Update heatmap data
                end
            elseif event.key == Keyboard.q
                # Quit - close the window
                # In GLMakie, we can just notify that user wants to close
                @info "Quit requested. Close the window to exit."
                # Note: Programmatic window closing in Makie can be tricky
                # Users can always close the window with the X button
            end
        end
    end

    # Return figure without display (KISS/DRY - let caller handle display)
    return fig
end

# ============================================================================
# Placeholder implementations for other functions
# ============================================================================
# Phase 2+ features - not yet implemented
# ============================================================================
# These will be added in future phases:
# - locs_viewer: Interactive localization viewer
# - render_volume: 3D volume rendering
# - render_projection: Projection rendering
# - animate_time_series: Time series animations
# - animate_acquisition: Acquisition animations

# ============================================================================
# Extension Initialization
# ============================================================================

"""
Register GLMakie backend when extension loads.
"""
function __init__()
    SMLMVis.Interact.register_backend!(:GLMakie, _stack_viewer_impl)
end

end # module SMLMVisGLMakieExt