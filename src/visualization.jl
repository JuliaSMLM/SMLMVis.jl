# File written by TheMoonThatRises July 2022
# Search "note" for important notes left
# Code uses a lot of (Observables and Interactions)[https://makie.juliaplots.org/v0.17.12/documentation/nodes/]

"""
    scaleim(in)

Scale the input from 0 to 1
"""
scaleim(in) = (in .- minimum(in[:])) ./ (maximum(in[:]) - minimum(in[:]))

"""
    parse_gt(framePos, gt)

Used to help `display` parse groundtruth matrix

# Arguments
 - `framePos`: The frame position to parse
 - `gt`: The groundtruth matrix of size (sz, sz, 6, nframes)
"""
function parse_gt(framePos, gt)
    frame = gt[:, :, :, framePos]
    markers = []

    for x in 1:size(frame)[1]
        for y in 1:size(frame)[2]
            if frame[x, y, 1] == 1.0
                push!(markers, [x, y, frame[x, y, :]])
            end
        end
    end

    return markers
end

"""
    parse_pt(framePos, pt)

Used to help `display` parse prediction matrix

# Arguments
 - `framePos`: The frame position to parse
 - `pt`: The prediction array
"""
parse_pt(framePos, pt) = filter(frame -> frame[9] == framePos, pt)

"""
    ellipse(σx, σy[, xc, yc])

Calculates the x and y coordinates to create an ellipse

# Arguments
 - `σx`: Semi-major/minor axis
 - `σy`: Semi-major/minor axis
 - `xc`: Center x coordinate
 - `yc`: Center y coordinate
"""
function ellipse(σx, σy; xc=0, yc=0)
    θ = [i for i in 0:0.01:(2pi + 0.1)]

    x = cos.(θ) * σx .+ xc
    y = sin.(θ) * σy .+ yc

    return GLMakie.Point2f.(x, y)
end

"""
    ob_value(object, func)

Find value of graph object and run inputted function to create an Observable

# Arguments
 - `object`: Graph object
 - `func`: Function to run with parameter `object.value`
"""
function ob_value(object, func::Function)::Observable
    observable = nothing

    if object isa GLMakie.Slider
        observable = GLMakie.lift(object.value) do pos
            func(round(Integer, pos))
        end
    elseif object isa GLMakie.Toggle
        observable = GLMakie.lift(object.active) do active
            func(active)
        end
    elseif object isa GLMakie.Button
        observable = GLMakie.on(object.clicks) do clicks
            func(clicks)
        end
    else
        @error "Unsupported observable: " * typeof(object)
    end

    return observable
end

"""
    display(data; predict=nothing, gt=nothing, pixel_size=nothing)

Returns Makie figure with a slider to scroll through different images with groundtruth markers and prediction circles

# Arguments
 - `data`: The images matrix of size (sz, sz, 1, nframes)
 - `predict`: The prediction array
 - `gt`: The groundtruth matrix of size (sz, sz, 6, nframes)
 - `pixel_size`: The size of a pixel in mms
"""
function display(data; predict=nothing, gt=nothing, pixel_size=nothing)
    npsize = isnothing(pixel_size) ? 1.0 : pixel_size # Set pixel size to 1.0 while not conflictig with pixel_size
    GLMakie.set_window_config!(; title="Display") # Set pop up title to display

    fig = GLMakie.Figure(; resolution=(2000, 1500)) # Create figure frame

    graphSlide = GLMakie.Slider(
        fig[2, 2]; range=1:0.01:size(data)[4], startvalue=1, height=30
    ) # Create slider from 1 to the amount of images. Increment size of 0.01 to allow for smooth scrolling

    toggles = Dict() # Dictionary to store all the toggles with the key the name of the toggle
    for label in filter( # Remove all false values
        x -> x != false,
        [ # Set values to false if the corresponding bit of information does not exist
            !isnothing(gt) ? ["Groundtruth", ["Hide", "Show"]] : false,
            !isnothing(predict) ? ["Prediction", ["Hide", "Show"]] : false,
            !isnothing(pixel_size) ? ["Scalebar", ["Hide", "Show"]] : false,
            ["Zoom", ["Unlock", "Lock"]],
        ],
    )
        toggle = GLMakie.Toggle(fig; active=true) # Create toggle
        toggles[lowercase(label[1])] = [ # Set toggle dict key to name
            toggle, # Set first value to toggle
            GLMakie.Label( # Set second value to label
                fig,
                GLMakie.lift(
                    x -> x ? "$(label[2][1]) $(label[1])" : "$(label[2][2]) $(label[1])",
                    toggle.active,
                );
                textsize=25,
            ),
        ]
    end

    buttons = [
        GLMakie.Button(fig; label=label, textsize=25) for
        label in ["Save as image", "Reset zoom"]
    ] # Create buttons

    frameImage = ob_value(graphSlide, framePos -> data[:, :, 1, framePos]) # Draw heatmap image

    title = ob_value(graphSlide, framePos -> "Frame: $(framePos)") # Set the title to frame number

    gtMouse = GLMakie.Observable("") # Create variable to hold groundtruth z "color" value of mouse hover
    ptMouse = GLMakie.Observable("") # Create variable to hold prediction z "color" value of mouse hover

    gtptSubtitle = GLMakie.lift(
        (gt, pt) ->
            "$(!isempty(gt) ? "Groundtruth: $(gt)" : "")$(!isempty(gt) && !isempty(pt) ? " | " : "")$(!isempty(pt) ? "Prediction: $(pt)" : "")$(isempty(gt) && isempty(pt) ? "-" : "")",
        gtMouse,
        ptMouse,
    ) # Create subtitle to display the gt/pt value [and differences] of the gt/pt the mouse is hovering over

    toggleValues = collect(values(toggles))
    interactives = fig[1, 1] = GridLayout() # Create new grid layout
    interactives[1, 1] = GLMakie.grid!(
        hcat(getindex.(toggleValues, 1), getindex.(toggleValues, 2));
        tellheight=false,
        tellwidth=false,
    ) # Draw toggles with toggles and tlabels on interactives grid layout
    interactives[2, 1] = buttons[1] # Create save image button on interactive grid layout beneath toggles
    interactives[3, 1] = buttons[2] # Create reset zoom button on interactive grid beneath save button

    GLMakie.colsize!(fig.layout, 1, Relative(1 / 5)) # Set column size of fig[:, 1] (Interactive elements)

    ax = GLMakie.Axis(
        fig[1, 2];
        aspect=GLMakie.DataAspect(), # Set aspect ratio to 1:1
        autolimitaspect=true, # Restrict plot to aspect ratio of 1:1
        title=title, # Set title
        titlesize=40, # Set title size
        subtitle=gtptSubtitle, # Set subtitle to gt and pt colors the mouse is over
        subtitlesize=25, # Set subtitle size
        limits=(0.5, size(data)[1] + 0.5, 0.5, size(data)[2] + 0.5), # Limit size to data size
        yreversed=true, # Set 0, 0 to top left
    ) # Create graph in middle

    GLMakie.hidedecorations!(ax) # Remove x and y axis markings
    GLMakie.hidespines!(ax) # Remove x and y spine axis

    GLMakie.heatmap!(ax, frameImage; colormap=:greys) # Draw images as grey-scale heatmaps

    # If a pixel size has been inputted ...
    if !isnothing(pixel_size)
        mmlist = [1, 2, 5] # Set the values the scalebar can use

        widthTenth = GLMakie.Observable(size(data)[1] / 10) # Get 1/10 of the width of the graph
        heightTenth = GLMakie.Observable(size(data)[2] / 10) # Get 1/10 of the height of the graph

        xoriginpos = GLMakie.Observable(0.0) # Get the x origin of the graph (top left x point) relative to field of view
        yoriginpos = GLMakie.Observable(0.0) # Get the y origin of the graph (top left y point) relative to field of view

        nearestmm = GLMakie.lift(
            width -> argmin(
                abs.(
                    width .-
                    10.0 .^ floor.(log10.(width ./ (mmlist ./ pixel_size))) .*
                    (mmlist ./ pixel_size)
                ),
            ),
            widthTenth,
        ) # Calculate best digit in mmlist
        mmWidth = GLMakie.lift(
            (width, nearestmm) -> round(
                10.0^floor(log10(width / (mmlist[nearestmm] / pixel_size))) *
                mmlist[nearestmm];
                sigdigits=1,
            ),
            widthTenth,
            nearestmm,
        ) # Get width of scalebar in mm

        x1 = GLMakie.lift(
            (width, origin, mmWidth) -> width * 9.5 + origin - mmWidth * pixel_size, # Left most value of scale bar x pos
            widthTenth,
            xoriginpos,
            mmWidth,
        )
        y1 = GLMakie.lift(
            (height, origin) -> height * 9.5 + origin,
            heightTenth,
            yoriginpos, # Center of scale bar y pos
        )
        x2 = GLMakie.lift((width, origin) -> width * 9.5 + origin, widthTenth, xoriginpos) # Right most value of scale bar x pos
        y2 = GLMakie.lift(
            (height, origin) -> height * 9.7 + origin,
            heightTenth,
            yoriginpos, # Heighest point of scale bar
        )
        y3 = GLMakie.lift(
            (height, origin) -> height * 9.3 + origin,
            heightTenth,
            yoriginpos, # Lowest point of scale bar
        )

        scalebarPos = GLMakie.lift(
            (x1, y1, x2, y2, y3) -> [
                GLMakie.Point2f(x1, y1),
                GLMakie.Point2f(x2, y1),
                GLMakie.Point2f(NaN, NaN),
                GLMakie.Point2f(x1, y3),
                GLMakie.Point2f(x1, y2),
                GLMakie.Point2f(NaN, NaN),
                GLMakie.Point2f(x2, y3),
                GLMakie.Point2f(x2, y2),
            ],
            x1,
            y1,
            x2,
            y2,
            y3,
        ) # Create scale bar Points based on x1, y1, x2, y2, y3

        scalebar = GLMakie.lines!(ax, scalebarPos; color="#FF3131", linewidth=5) # Create scale bar with scalebarPos as Points

        scalebarString = GLMakie.lift(mmWidth -> "$mmWidth mm", mmWidth) # Create text
        scalebarText = GLMakie.text!(
            ax,
            GLMakie.lift((x1, x2) -> (x1 + x2) / 2, x1, x2),
            GLMakie.lift(y -> y, y2);
            text=scalebarString,
            color="#FF3131",
            align=(:center, :center),
        ) # Create text for scale bar on the middle beneath the scale bar

        GLMakie.connect!(scalebar.visible, toggles["scalebar"][1].active) # Connect scale bar to scalebar toggle
        GLMakie.connect!(scalebarText.visible, toggles["scalebar"][1].active) # Connect scale bar text to scalebar toggle
    end

    # If groundtruth has been inputted ...
    if !isnothing(gt)
        frameGT = ob_value(
            graphSlide,
            framePos -> [GLMakie.Point2f(i[1], i[2]) for i in parse_gt(framePos, gt)],
        ) # Place coords of ground truths

        colorGT = ob_value(
            graphSlide, framePos -> [i[3][4] for i in parse_gt(framePos, gt)]
        ) # Get the color for ground truths

        gtMarkers = GLMakie.scatter!(
            ax,
            frameGT;
            marker=:xcross,
            markersize=18,
            color=colorGT,
            colormap=:isoluminant_cgo_80_c38_n256,
        ) # Place gt heatmap markers

        GLMakie.connect!(gtMarkers.visible, toggles["groundtruth"][1].active) # Connect groundtruth markers to groundtruth toggle
    end

    # If prediction has been inputted ...
    if !isnothing(predict)
        colorPT = ob_value(
            graphSlide,
            framePos ->
                cat([fill(i[3], 100) for i in parse_pt(framePos, predict)]...; dims=1), # Do note that the 100 is an arbitrary value that seems to work with the test data
        ) # Get the color for predictions

        predictEllipses = ob_value(
            graphSlide,
            framePos -> cat(
                [
                    [ellipse(i[5], i[6]; xc=i[1], yc=i[2])..., Point2f(NaN, NaN)] for
                    i in parse_pt(framePos, predict)
                ]...;
                dims=1,
            ),
        ) # Create prediction ellipses

        predictions = GLMakie.lines!(
            ax, predictEllipses; colormap=:isoluminant_cgo_80_c38_n256, color=colorPT
        ) # Draw prediction ellipses

        GLMakie.connect!(predictions.visible, toggles["prediction"][1].active) # Connect prediction markers to prediction toggle
    end

    GLMakie.Colorbar(
        fig[1, 3];
        colormap=:isoluminant_cgo_80_c38_n256,
        limits=(-1, 1),
        width=40,
        ticklabelsize=20,
        tellheight=false,
    ) # Create colorbar based on isoluminant_cgo_80_c38_n256

    colsize!(fig.layout, 3, Relative(1 / 10)) # Set column size of fig[:, 3] (Colorbar)

    ob_value(
        toggles["zoom"][1],
        active -> [
            setproperty!(ax, value[1], active == value[2]) for value in [
                [:xzoomlock, true],
                [:yzoomlock, true],
                [:xpanlock, true],
                [:ypanlock, true],
                [:xrectzoom, false],
                [:yrectzoom, false],
            ]
        ], # Note that :xrectzoom and :yrectzoom are reversed from the others so the pair is required
    ) # Toggle zoom lock

    ob_value(
        buttons[1],
        clicks -> begin
            tempfig = GLMakie.Figure(; figure_padding=0) # Create temp figure to save image
            tempax = GLMakie.Axis(
                tempfig[1, 1]; # Set to 1, 1 of temp figure
                aspect=GLMakie.DataAspect(), # Set aspect ratio to 1:1
                limits=(0.5, size(data)[1] + 0.5, 0.5, size(data)[2] + 0.5), # Limit axis to size of data
                yreversed=true, # Set 0, 0 to top left
            ) # Create temp axis
            # tempax.scene=ax.scene
            # println(fieldnames(typeof(ax)))

            GLMakie.hidedecorations!(tempax) # Remove x and y axis markings
            GLMakie.hidespines!(tempax) # Remove x and y spine axis

            GLMakie.heatmap!(tempax, frameImage; colormap=:greys) # Draw heatmap

            !isnothing(gt) &&
                toggles["groundtruth"][1].active[] &&
                GLMakie.scatter!(
                    tempax,
                    frameGT;
                    marker=:xcross,
                    markersize=18,
                    color=colorGT,
                    colormap=:isoluminant_cgo_80_c38_n256,
                ) # Draw gt markings
            !isnothing(predict) &&
                toggles["prediction"][1].active[] &&
                GLMakie.lines!(
                    tempax,
                    predictEllipses;
                    colormap=:isoluminant_cgo_80_c38_n256,
                    color=colorPT,
                ) # Draw prediction ellipses

            GLMakie.save(
                "figure_frame$(round(Integer, graphSlide.value[]))_$(time()).png",
                tempfig;
                resolution=(1500, 1500),
            ) # Save temp figure

            GLMakie.empty!(tempfig)
        end,
    ) # Save fig to png

    ob_value(buttons[2], clicks -> begin
        GLMakie.reset_limits!(ax) # Reset zoom

        # Reset scale bar
        widthTenth[] = size(data)[1] / 10
        heightTenth[] = size(data)[2] / 10

        xoriginpos[] = 0
        yoriginpos[] = 0
    end) # Reset zoom

    # Detect if the mouse wheel is scrolling
    GLMakie.on(GLMakie.events(ax).scroll; priority=100) do event
        if !toggles["zoom"][1].active[]
            ### Begin:
            ### Scroll code copied and adapted from https://github.com/JuliaPlots/Makie.jl/blob/6c0f7c758a1446aa8fa98c5074f40be215b58bc2/src/makielayout/interactions.jl#L228
            _, s = ax.interactions[:scrollzoom]
            zoom = event[2]

            tlimits = ax.targetlimits

            scene = ax.scene
            e = GLMakie.events(scene)
            cam = GLMakie.camera(scene)

            if zoom != 0
                pa = GLMakie.pixelarea(scene)[]

                z = (1.0f0 - s.speed)^zoom

                mp_axscene = GLMakie.Vec4f((e.mouseposition[] .- pa.origin)..., 0, 1)

                # first to normal -1..1 space
                mp_axfraction =
                    (cam.pixel_space[] * mp_axscene)[GLMakie.Vec(1, 2)] .*
                    # now to 1..-1 if an axis is reversed to correct zoom point
                    (-2 .* ((ax.xreversed[], ax.yreversed[])) .+ 1) .*
                    # now to 0..1
                    0.5 .+ 0.5

                xscale = ax.xscale[]
                yscale = ax.yscale[]

                transf = (xscale, yscale)
                tlimits_trans = Makie.apply_transform(transf, tlimits[])

                xorigin = tlimits_trans.origin[1]
                yorigin = tlimits_trans.origin[2]

                xwidth = tlimits_trans.widths[1]
                ywidth = tlimits_trans.widths[2]

                newxwidth = xwidth * z
                newywidth = ywidth * z

                newxorigin = xorigin + mp_axfraction[1] * (xwidth - newxwidth)
                newyorigin = yorigin + mp_axfraction[2] * (ywidth - newywidth)

                ### End

                widthTenth[] = newxwidth / 10
                heightTenth[] = newywidth / 10

                xoriginpos[] = newxorigin
                yoriginpos[] = newyorigin
            end
        end
    end

    GLMakie.on(GLMakie.events(fig).keyboardbutton) do event # When keyboard button is pressed
        isBetween = graphSlide.value[] <= size(data)[4] && graphSlide.value[] >= 1 # If graphSlide value is between 1 and 100

        keyboard = GLMakie.events(fig).keyboardstate # Get all buttons currently pressed

        if in(GLMakie.Keyboard.left, keyboard) && isBetween # If left arrow key is pressed, then move to previous image
            GLMakie.set_close_to!(graphSlide, round(Integer, graphSlide.value[] - 1))
        elseif in(GLMakie.Keyboard.right, keyboard) && isBetween # If right arrow key is pressed, then move to next image
            GLMakie.set_close_to!(graphSlide, round(graphSlide.value[] + 1))
        elseif in(GLMakie.Keyboard.g, keyboard) && !isnothing(gt) # If g is pressed, then toggle ground truths
            toggles["groundtruth"][1].active = !toggles["groundtruth"][1].active[]
        elseif in(GLMakie.Keyboard.p, keyboard) && !isnothing(predict) # If p is pressed, then toggle predictions
            toggles["prediction"][1].active = !toggles["prediction"][1].active[]
        elseif in(GLMakie.Keyboard.z, keyboard) # If z is pressed, then toggle zoom
            toggles["zoom"][1].active = !toggles["zoom"][1].active[]
        elseif in(GLMakie.Keyboard.left_control, keyboard) &&
            in(GLMakie.Keyboard.s, keyboard) &&
            event.action == GLMakie.Keyboard.press # If ctrl-s is pressed, then save as image
            buttons[1].clicks[] += 1
        elseif in(GLMakie.Keyboard.space, keyboard) # If space is pressed, then reset zoom
            buttons[2].clicks[] += 1
        end
    end

    on(GLMakie.events(fig).mouseposition; priority=100) do _ # Get position of the mouse
        position = GLMakie.mouseposition(ax) # Get position of mouse relative to graph "axis"

        if position[1] >= ax.limits[][1] &&
            position[1] <= ax.limits[][2] &&
            position[2] >= ax.limits[][3] &&
            position[2] <= ax.limits[][4] # If mouse is inside ax "Axis"
            gtfound = false # If mouse is on gt "found"
            ptfound = false # If mouse is inside a prediction "found"

            # If groundtruth exists
            if !isnothing(gt)
                for coord in parse_gt(round(Integer, graphSlide.value[]), gt) # Loop through all gts
                    if (
                        position[1] >= coord[1] &&
                        position[1] <= coord[1] + 1 &&
                        position[2] >= coord[2] &&
                        position[2] <= coord[2] + 1
                    ) && toggles["groundtruth"][1].active[] # If mouse is on a gt
                        coord = [coord[1:2]..., coord[3]...] # Turn coord into a 1D array
                        coord = round.(coord; digits=3) # Round all values to 3 digits
                        # NOTE: This string controls the "Groundtruth" part of the graph subtitle. Coord is an array of: x, y, z, has emitter, x shift, y shift, z, nphotons
                        gtMouse[] = "(x=$(coord[1] * npsize), y=$(coord[2] * npsize), z=$(coord[6]))" # Set gtMouse to x, y, z of gt.
                        gtfound = true # gt is found
                        break # Exit for loop
                    end
                end
            end

            # If prediction exists
            if !isnothing(predict)
                for coord in parse_pt(round(Integer, graphSlide.value[]), predict)
                    if (
                        position[1] >= coord[1] - coord[5] &&
                        position[1] <= coord[1] + coord[5] &&
                        position[2] >= coord[2] - coord[6] &&
                        position[2] <= coord[2] + coord[6]
                    ) && toggles["prediction"][1].active[] # If mouse is inside the pt ellipse
                        coord = round.(coord; digits=3) # Round all values to 3 digits
                        # NOTE: This string controls the "Prediction" part of the graph subtitle. Coord is an array of: x, y, z, N, σx, σy, σz, σN, framenum
                        ptMouse[] = "(x=$(coord[1] * npsize), y=$(coord[2] * npsize), z=$(coord[3]))" # Set ptMouse to x, y, z of pt.
                        ptfound = true # pt is found
                        break # Exit for loop
                    end
                end
            end

            if !gtfound # Set gtMouse to empty string if mouse is not on gt
                gtMouse[] = ""
            end
            if !ptfound # Set ptMouse to empty string if mouse is not on pt
                ptMouse[] = ""
            end
        end

        # Update scale bar as the mouse pans
        if ax.scene.events.mousebutton.val.button == Makie.Mouse.right && (
            ax.scene.events.mousebutton.val.action == GLMakie.Mouse.press ||
            ax.scene.events.mousebutton.val.action == GLMakie.Mouse.pressed
        )
            ### Begin:
            ### Copied from https://github.com/JuliaPlots/Makie.jl/blob/6c0f7c758a1446aa8fa98c5074f40be215b58bc2/src/makielayout/interactions.jl#L321 with modifications
            tlimits = ax.targetlimits

            xscale = ax.xscale[]
            yscale = ax.yscale[]

            transf = (xscale, yscale)
            tlimits_trans = Makie.apply_transform(transf, tlimits[])

            xoriginpos[] = tlimits_trans.origin[1]
            yoriginpos[] = tlimits_trans.origin[2]

            ### End
        end
    end

    return fig # Return the GLMakie window
end
