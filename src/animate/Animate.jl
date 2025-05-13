module Animate

include("time_series.jl")
include("export.jl")

export animate_time_series, animate_acquisition
export export_video, export_frames

# Convenience aliases
const create_time_series = animate_time_series
const create_rotation_video = animate_acquisition  # Assuming this is the equivalent

export create_time_series, create_rotation_video

end # module Animate