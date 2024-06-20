using Revise
using GLMakie
using FileIO
using JLD2
using SMLMVis




# # This is #2 working code
# Variable to hold loaded data
# loaded_dict = Ref{Union{Nothing, Dict{String, Any}}}(nothing)

# function open_file(status_label)
#     pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5"
#     filename = "data.jld2"
#     fn = joinpath(pathname, filename)
    
#     try
#         # Load the data from the .jld2 file
#         data = load(fn)
#         loaded_dict[] = data
#         # Update the status label
#         status_label.text = "Data loaded successfully."
#         # Print the data to the console (or handle it as needed)
#         #println("Data loaded from file: ", data)
#     catch e
#         status_label.text = "Error loading data."
#         println("Error loading data: ", e)
#     end
# end

# function render_image(status_label)
#     try
#         if loaded_dict[] !== nothing
#             dict = loaded_dict[]
            
#             required_keys = ["x", "y", "z", "σ_x", "σ_y"]
#             if all(k -> haskey(dict, k), required_keys)
#                 x_range = (minimum(dict["x"]), maximum(dict["x"]))
#                 y_range = (minimum(dict["y"]), maximum(dict["y"]))
#                 z_range = (minimum(dict["z"]), maximum(dict["z"]))
                
#                 out, (cm, z_range) = SMLMVis.render_blobs(
#                     x_range,
#                     y_range,
#                     dict["x"],
#                     dict["y"],
#                     dict["σ_x"],
#                     dict["σ_y"],
#                     normalization=:integral,
#                     n_sigmas=3,
#                     colormap=:jet,
#                     z=dict["z"],
#                     z_range=z_range,
#                     zoom=10,
#                     percentile_cutoff=0.90
#                 )
                
#                 display(out)
#                 status_label.text = "Rendering complete."
#             else
#                 status_label.text = "Data missing required keys."
#                 println("Data missing required keys.")
#             end
#         else
#             status_label.text = "No file loaded to render."
#             println("No file loaded to render.")
#         end
#     catch e
#         status_label.text = "Error rendering image."
#         println("Error rendering image: ", e)
#     end
# end

# function create_gui()
#     fig = Figure(resolution = (400, 300), title = "GLMakie GUI Example")
#     ax = Axis(fig[1, 1], title = "GLMakie GUI Example")

#     open_button = Button(fig[2, 1], label = "Open .jld2 File")
#     render_button = Button(fig[3, 1], label = "Render Image")
#     status_label = Label(fig[4, 1], "Status: Ready")

#     # Connect the open button click to the open_file function
#     on(open_button.clicks) do click
#         open_file(status_label)
#     end

#     # Connect the render button click to the render_image function
#     on(render_button.clicks) do click
#         render_image(status_label)
#     end

#     display(fig)
# end

# create_gui()


# This is #1 working code
# using GLMakie
# using FileIO
# using JLD2

# function open_file()
#     pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5"
#     filename = "data.jld2"
#     fn = joinpath(pathname, filename)
    
#     # Load the data from the .jld2 file
#     data = load(fn)
#     # Print the data to the console (or handle it as needed)
#     #println("Data loaded from file: ", data)
# end

# function create_gui()
#     fig = Figure(resolution = (700, 700), title = "GLMakie GUI Example")
#     ax = GLMakie.Axis(fig[1, 1], title = "GLMakie GUI Example")

#     button = Button(fig[2, 1], label = "Open .jld2 File")

#     # Connect the button click to the open_file function
#     on(button.clicks) do click
#         open_file()
#     end

#     display(fig)
# end

# create_gui()
