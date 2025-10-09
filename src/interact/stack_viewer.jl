# Stack viewer implementation with smart backend dispatch
#
# This stub automatically detects and dispatches to the appropriate backend.
# Actual implementations are in:
# - SMLMVisGLMakieExt for GLMakie (desktop windows)
# - SMLMVisWGLMakieExt for WGLMakie (browser-based)

"""
    stack_viewer(data::AbstractArray; backend::Symbol=:auto, kwargs...)

Interactive viewer for multidimensional image stacks (1D-4D).

Automatically selects the best available backend based on your environment,
or you can explicitly specify one.

# Arguments
- `data::AbstractArray`: 1D-4D array of image data
- `backend::Symbol=:auto`: Backend selection
  - `:auto` (default) - Automatically detect best backend
  - `:GLMakie` - Force GLMakie (desktop native window)
  - `:WGLMakie` - Force WGLMakie (browser-based)
- `contrast::Symbol=:linear`: Contrast method (`:linear`, `:log`, `:sqrt`, `:equalize`)
- `clip::Tuple{Float64,Float64}=(0.001, 0.999)`: Percentile clipping
- `zoom::Real=1.0`: Initial zoom factor
- `title::String="Stack Viewer"`: Window title
- `pixel_size::Union{Real,Nothing}=nothing`: Physical pixel size in μm
- `z_step::Union{Real,Nothing}=nothing`: Z-slice spacing in μm
- `frame_interval::Union{Real,Nothing}=nothing`: Time between frames in seconds

# Keyboard Controls
- `n`/`p`: Next/previous slice
- `i`/`o`: Zoom in/out
- `q`: Quit (close window)

# Examples
```julia
using SMLMVis.Interact

# Automatic backend selection (recommended)
data = rand(Float32, 256, 256, 50)
stack_viewer(data)

# Explicit backend selection
using WGLMakie  # Load backend first
stack_viewer(data; backend=:WGLMakie)

# With physical scale
stack_viewer(data; pixel_size=0.1, z_step=0.2)

# Check available backends
backend_info()
```

# Backend Installation
If no backend is available, you'll see instructions to install one:

**For local desktop:**
```julia
using Pkg
Pkg.add("GLMakie")
using GLMakie
```

**For remote/SSH/headless:**
```julia
using Pkg
Pkg.add("WGLMakie")
using WGLMakie
```

# See Also
- `backend_info()`: Check available backends and environment
- `use_backend!()`: Set preferred backend for session
- `locs_viewer()`: Viewer for SMLD localization data
"""
function stack_viewer(data::AbstractArray; backend::Symbol=:auto, kwargs...)
    # Resolve backend selection
    selected_backend = backend
    if backend == :auto
        selected_backend = detect_best_backend()
    end

    # Check if backend is available
    if !has_backend(selected_backend)
        # Generate helpful error message
        available = list_available_backends()

        error_msg = """
        Backend :$selected_backend is not available.

        """

        if !isempty(available)
            error_msg *= """
            Available backends: $(join(available, ", "))

            To use an available backend:
                stack_viewer(data; backend=$(first(available)))

            """
        end

        error_msg *= """
        To install :$selected_backend backend:
            using Pkg
            Pkg.add("$(selected_backend)Makie")
            using $(selected_backend)Makie
            using SMLMVis.Interact
            stack_viewer(data)

        Or check your environment:
            using SMLMVis.Interact
            backend_info()
        """

        error(error_msg)
    end

    # Dispatch to registered implementation
    impl = BACKEND_IMPLEMENTATIONS[selected_backend]
    return impl(data; kwargs...)
end

"""
    locs_viewer(locs; kwargs...)

Interactive viewer for localization data.

Requires GLMakie or WGLMakie. See `stack_viewer` for installation instructions.
"""
function locs_viewer(locs; kwargs...)
    error("""
    locs_viewer requires GLMakie or WGLMakie to be loaded.
    See help for stack_viewer for installation instructions.
    """)
end

# Convenience aliases
const view_stack = stack_viewer
const view_localizations = locs_viewer