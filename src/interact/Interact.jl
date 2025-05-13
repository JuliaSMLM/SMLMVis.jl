module Interact

include("stack_viewer.jl")

export stack_viewer, locs_viewer

# Convenience aliases
const view_stack = stack_viewer
const view_localizations = locs_viewer

export view_stack, view_localizations

end # module Interact