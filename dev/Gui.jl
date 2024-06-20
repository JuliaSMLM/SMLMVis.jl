using Revise
using GLMakie
using FileIO
using JLD2
using SMLMVis

# Inspect the contents of the JLD2 file
filepath = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"
# Function to inspect the contents of the JLD2 file
# Function to inspect the contents of the JLD2 file
function inspect_jld2(filepath)
    try
        JLD2.jldopen(filepath, "r") do file
            return collect(keys(file))
        end
    catch e
        println("Error inspecting JLD2 file: ", e)
        return []
    end
end

# Inspect the file and print the keys
file_keys = inspect_jld2(filepath)
println("Keys in the file: ", file_keys)

# Optimized function to load the dict from the file
function load_dict(filepath, key)
    try
        JLD2.jldopen(filepath, "r") do file
            return file[key]
        end
    catch e
        println("Error loading dict: ", e)
        return nothing
    end
end

# Create a figure for the GUI
fig = Figure(resolution = (800, 800))

# Add a label to display the status
status_label = Label(fig[1, 1], "Click the button to load smld.jld2")

# Create a button for loading the file
load_button = Button(fig[2, 1], label = "Load smld.jld2")

# Create a button for rendering the image
render_button = Button(fig[3, 1], label = "Render Image")

# Variable to store loaded dictionary
loaded_dict = Ref(nothing)

# Define the button click action for loading the file
on(load_button.clicks) do _
    try
        # Update the key to the correct one after inspection
        status_label.text = "Loading, please wait..."
        dict = load_dict(filepath, "smld")
        if dict !== nothing
            status_label.text = "File loaded successfully!"
            loaded_dict[] = dict
        else
            status_label.text = "Failed to load the file."
        end
    catch e
        status_label.text = "Failed to load the file."
        println("Error: ", e)
    end
end

# Define the button click action for rendering the image
on(render_button.clicks) do _
    try
        if loaded_dict[] !== nothing
            dict = loaded_dict[]
            x_range = (minimum(dict["x"]), maximum(dict["x"]))
            y_range = (minimum(dict["y"]), maximum(dict["y"]))
            z_range = (minimum(dict["z"]), maximum(dict["z"]))
            
            out, (cm, z_range) = SMLMVis.render_blobs(
                x_range,
                y_range,
                dict["x"],
                dict["y"],
                dict["σ_x"],
                dict["σ_y"],
                normalization=:integral,
                n_sigmas=3,
                colormap=:jet,
                z=dict["z"],
                z_range=z_range,
                zoom=10,
                percentile_cutoff=0.90
            )
            
            display(out)
        else
            status_label.text = "No file loaded to render."
        end
    catch e
        status_label.text = "Error rendering image."
        println("Error: ", e)
    end
end

# Display the figure
display(fig)