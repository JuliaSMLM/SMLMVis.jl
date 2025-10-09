# Stack viewer implementation
#
# NOTE: These are stub functions that will be extended by package extensions.
# Actual implementations are in:
# - SMLMVisGLMakieExt for GLMakie (desktop windows)
# - SMLMVisWGLMakieExt for WGLMakie (browser-based)

"""
    stack_viewer(stack; kwargs...)

Interactive viewer for image stacks.

Requires GLMakie or WGLMakie to be loaded. Install with:
```julia
using Pkg
Pkg.add("GLMakie")  # For desktop
# or
Pkg.add("WGLMakie")  # For remote/headless
```

Then load before using:
```julia
using GLMakie  # or WGLMakie
using SMLMVis.Interact
stack_viewer(my_data)
```
"""
function stack_viewer(stack; kwargs...)
    error("""
    stack_viewer requires GLMakie or WGLMakie to be loaded.

    Install and load one of:
      using Pkg; Pkg.add("GLMakie"); using GLMakie  # Desktop
      using Pkg; Pkg.add("WGLMakie"); using WGLMakie  # Remote/browser

    Then try again:
      using SMLMVis.Interact
      stack_viewer(data)
    """)
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