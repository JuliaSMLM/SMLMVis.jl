# This part auto generates the SR image & when hist button is clicked, it plots the histogram of z values within 
# the polygon points given manually. 
using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
using GLMakie
using Statistics
using JLD2
using GeometryBasics 
using PolygonOps: inpolygon
using Distributions

pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5"
filename = "data.jld2"
fn = joinpath(pathname,filename)
data = load(fn)
loc_data = data["loc_data"]
println("Type of loc_data:", typeof(loc_data))

x_raw = loc_data["x"]
y_raw = loc_data["y"]
z_raw = loc_data["z"]  # nm ??


σ_x_raw = loc_data["crlb"][:, 1]
σ_y_raw = loc_data["crlb"][:, 2]
σ_z_raw = loc_data["crlb"][:, 5]  # check - is this in nm ??
σ_photons_raw = loc_data["crlb"][:, 3] #  
σ_bg_raw = loc_data["crlb"][:, 4] 

# Threshold 
σ_xy_max = .2
σ_z_max = 240
mask_tsh = (σ_x_raw .< σ_xy_max) .& (σ_y_raw .< σ_xy_max) .& (σ_z_raw .< σ_z_max)

x = x_raw[mask_tsh]
y= y_raw[mask_tsh]
z = Float64.(z_raw[mask_tsh])
σ_x = σ_x_raw[mask_tsh]
σ_y = σ_y_raw[mask_tsh]
σ_z = σ_z_raw[mask_tsh]
photons = loc_data["photon"][mask_tsh]
σ_photons = σ_photons_raw[mask_tsh]
bg = loc_data["bg"][mask_tsh]
σ_bg = σ_bg_raw[mask_tsh]
# create empty array
connectID = zeros(Int, length(x))
framenum = zeros(Int, length(x))
datasetnum = zeros(Int, length(x))
datasize = [256; 256]
nframes = 1
ndatasets = 1

smld = SMLMData.SMLD3D(1) # 6323878
smld.x = x
smld.y = y
smld.z = z
smld.σ_x = σ_x
smld.σ_y = σ_y
smld.σ_z = σ_z
smld.photons = photons
smld.σ_photons = σ_photons
smld.bg = bg
smld.σ_bg = σ_bg
smld.framenum = framenum
smld.datasetnum = datasetnum
smld.datasize = datasize
smld.nframes = nframes
smld.ndatasets = ndatasets
smld.datafields = (:connectID, :x, :y, :z, :σ_x, :σ_y, :σ_z, :photons, :σ_photons, :bg, :σ_bg, :framenum, :datasetnum)
smld  

# Optional parameters
normalization = :integral
n_sigmas = 3
colormap = :jet
#z_range = (0.0, 120.0)
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
zoom = 10
percentile_cutoff = 0.90

function draw_Roi(manual_polygon_points)

    #z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))

    # Define global variables
    global localizations_z = Float64[]
    global saved_polygon_points = []

    # Function to set polygon points manually
    function set_polygon_points(points)
        global saved_polygon_points
        saved_polygon_points = points
    end

    # Function to extract and plot the SMLD.z within a polygon and histogram as a separate figure
    function get_polygon_points(p1, p2, p3, p4)
        return [p1, p2, p3, p4, p1]
    end

    function interactive_plot_with_polygon_tool(ax, image)
        points = Observable(Point2f0[])
        mask_ready = Observable(false)
        mask = Observable(Point2f0[])

        on(events(ax.scene).mousebutton) do event
            if event.button == Mouse.left && event.action == Mouse.press
                pos = mouseposition(ax.scene)
                if all(pos .>= 0) && all(pos .<= Point2f0(size(image)))
                    push!(points[], pos)
                    notify(points)
                    scatter!(ax, [pos], color=:red, markersize=4)
                    if length(points[]) == 4
                        polygon_points = get_polygon_points(points[][1], points[][2], points[][3], points[][4])
                        lines!(ax, polygon_points, color=:red, linewidth=2)
                        println("Coordinates of the polygon: ", polygon_points)
                        mask[] = polygon_points
                        println("The mask is: ", mask[])
                        points[] = []
                        notify(points)
                        mask_ready[] = true
                        saved_polygon_points = polygon_points # Save the polygon points
                    end
                end
            end
        end

        return points, mask, mask_ready
    end

    function extract_polygon_data_and_points(smld, polygon_points, zoom)
        println("Polygon points: ", polygon_points)

        localizations = []
        localizations_z = []

        for i in 1:length(smld.x)
            scaled_x = smld.x[i] * zoom
            scaled_y = smld.y[i] * zoom
            point = Point2f0(scaled_x, scaled_y)
            if inpolygon(point, polygon_points) != 0
                push!(localizations, (smld.y[i], smld.x[i]))
                push!(localizations_z, smld.z[i])
            end
        end

        println("Number of localizations inside the polygon: ", length(localizations))

        return localizations, localizations_z
    end

    function render_image(button)
        global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff, image_axis, localizations_z, saved_polygon_points

        if !isa(z_range, Tuple{Real,Real})
            error("z_range is not of the correct type. It should be a tuple of two real numbers.")
        end

        out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)

        image!(image_axis, out', show_axes=false)
        status_label.text = "SR Image Rendered"

        points, mask, mask_ready = interactive_plot_with_polygon_tool(image_axis, out)

        on(mask_ready) do ready
            if ready
                localizations, localizations_z = extract_polygon_data_and_points(smld, mask[], zoom)
                println("Number of localizations inside the polygon: ", length(localizations))
            else
                println("No polygon was defined.")
            end
        end

        # Plot saved polygon points if they exist
        if !isempty(saved_polygon_points)
            lines!(image_axis, saved_polygon_points, color=:red, linewidth=2)
            localizations, localizations_z = extract_polygon_data_and_points(smld, saved_polygon_points, zoom)
        end
    end

    fig = Figure(resolution=(1000, 800))

    # Add the status label at the top
    status_label = Label(fig, text="SR Image Visualization", halign=:center, valign=:center)

    # Define the axes and buttons
    global image_axis = GLMakie.Axis(fig[2, 1], title="Render Image Axis", width=500, height=450, yreversed=true)
    ax2 = GLMakie.Axis(fig[2, 2], title="Histogram Axis", width=400, height=350)
    render_button = Button(fig[3, 1], label="Render Image")
    hist_button = Button(fig[3, 2], label="Plot Histogram")

    # Add a label to display the Gaussian fit parameters
    fit_params_label = Label(fig, text="", halign=:left, valign=:top)

    # Arrange elements in the layout
    fig.layout.rowsizes = [Auto(0.1), Auto(1), Auto(0.1)]
    fig.layout.colsizes = [Auto(1), Auto(1)]

    # Add elements to the layout
    fig[1, 1:2] = status_label
    fig[2, 1] = image_axis
    fig[2, 2] = ax2
    fig[3, 1] = render_button
    fig[3, 2] = hist_button
    fig[4, 2] = fit_params_label

    function plot_histogram(button)
        global localizations_z, saved_polygon_points

        if isempty(saved_polygon_points)
            println("No polygon points saved. Please define a polygon first.")
            return
        end

        if isempty(localizations_z)
            println("No localizations inside the polygon. Cannot plot histogram.")
            return
        end

        # Clear the axis completely
        empty!(ax2.scene)

        z_coords = Float64.(localizations_z)

        hist!(ax2, localizations_z, bins=70, color=1, colormap=:tab10, colorrange=(1, 10), strokewidth=0.4, strokecolor=:white)
        fit_result = fit(Distributions.Normal, z_coords)
        μ = fit_result.μ
        σ = fit_result.σ

        x = range(minimum(z_coords), stop=maximum(z_coords), length=100)
        y = pdf.(Distributions.Normal(μ, σ), x) * length(z_coords) * (maximum(z_coords) - minimum(z_coords)) / 70

        label = "Gaussian fit: <d> = $(round(μ, digits=2)) nm, σ = $(round(σ, digits=2)) nm"
        lines!(ax2, x, y, color=:red, linewidth=4, label=label)

        # Update the fit parameters label
        fit_params_label.text = label

        println("Mean (μ): ", μ)
        println("Standard Deviation (σ): ", σ)
    end

    on(render_button.clicks) do _
        render_image(render_button)
    end

    on(hist_button.clicks) do _
        plot_histogram(hist_button)
    end

    display(fig)
    set_polygon_points(manual_polygon_points)
    render_image(render_button)

end

# Manually set polygon points and render image
# manual_polygon_points = [Point2f0(510.66107, 420.85706), Point2f0(542.4695, 391.33902), Point2f0(617.68994, 474.3986), Point2f0(593.38184, 502.08063), Point2f0(510.66107, 420.85706)]
# draw_Roi(manual_polygon_points)