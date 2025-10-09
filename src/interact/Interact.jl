module Interact

# Backend detection and environment utilities
include("backend_detection.jl")

# Backend registry system
# Extensions register their implementations here when loaded
const BACKEND_IMPLEMENTATIONS = Dict{Symbol, Any}()

"""
    register_backend!(name::Symbol, impl)

Register a backend implementation. Called by package extensions when they load.

# Arguments
- `name::Symbol`: Backend name (`:GLMakie`, `:WGLMakie`, etc.)
- `impl`: Implementation function that takes (data; kwargs...) and returns a Figure

# Examples
```julia
# Called by extension's __init__():
SMLMVis.Interact.register_backend!(:GLMakie, _stack_viewer_impl)
```
"""
function register_backend!(name::Symbol, impl)
    @debug "Registering backend: $name"
    BACKEND_IMPLEMENTATIONS[name] = impl
    @info "SMLMVis: $name backend registered for interactive viewing"
end

"""
    has_backend(name::Symbol)::Bool

Check if a specific backend is available (loaded and registered).
"""
function has_backend(name::Symbol)::Bool
    return haskey(BACKEND_IMPLEMENTATIONS, name)
end

"""
    list_available_backends()::Vector{Symbol}

Get list of all currently available backends.
"""
function list_available_backends()::Vector{Symbol}
    return collect(keys(BACKEND_IMPLEMENTATIONS))
end

"""
    backend_info()

Display diagnostic information about available backends and current environment.

Shows:
- Environment detection (headless, SSH, notebook, display)
- Available backends
- Recommended backend for current environment

Useful for troubleshooting backend selection issues.

# Examples
```julia
using SMLMVis.Interact
backend_info()
```
"""
function backend_info()
    println("SMLMVis Interactive Backend Status")
    println("="^70)
    println()

    # Environment detection
    println("Environment Detection:")
    println("  Headless:      ", is_headless())
    println("  Remote SSH:    ", is_remote_session())
    println("  Notebook:      ", is_notebook())
    println("  Has Display:   ", has_display())
    println()

    # Available backends
    println("Available Backends:")
    available = list_available_backends()
    if isempty(available)
        println("  None loaded")
        println()
        println(recommend_backend_installation())
    else
        for backend in available
            println("  ✓ $backend")
        end
        println()
    end

    # Recommended
    recommended = detect_best_backend()
    println("Recommended Backend: $recommended")

    if !has_backend(recommended) && recommended != :none
        println("  (not currently loaded - will need to install/load)")
        println()
        println("  To load:")
        println("    using $(recommended)Makie")
    end
    println()
end

"""
    use_backend!(backend::Symbol)

Explicitly set preferred backend for this session via environment variable.

# Arguments
- `backend::Symbol`: Backend name (`:GLMakie`, `:WGLMakie`)

# Examples
```julia
using SMLMVis.Interact
use_backend!(:WGLMakie)  # Force WGLMakie even if GLMakie available
stack_viewer(data)        # Will use WGLMakie
```
"""
function use_backend!(backend::Symbol)
    ENV["SMLMVIS_BACKEND"] = string(backend)
    @info "Backend preference set to: $backend"
    @info "Will be used for next stack_viewer() call"
end

# Include viewer implementations (stubs)
include("stack_viewer.jl")

export stack_viewer, locs_viewer
export view_stack, view_localizations
export backend_info, use_backend!

end # module Interact