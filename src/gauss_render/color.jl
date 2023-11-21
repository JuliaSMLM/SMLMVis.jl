

function is_empty(pixel)
    # Define 'empty' based on your specific context, e.g., zero color, transparency, etc.
    return pixel == RGB{Float32}(0.0, 0.0, 0.0)
end

function composite_slices(slices)
    # Assuming slices are ordered from top to bottom
    z_max, y_max, x_max = size(slices)
    final_image = zeros(RGB{Float32}, y_max, x_max)

    for z in z_max:-1:1
        for y in 1:y_max
            for x in 1:x_max
                # Replace the pixel color if the current slice pixel is not 'empty'
                # Define 'empty' based on your specific context, e.g., zero color, transparency, etc.
                if !is_empty(slices[z, y, x]) 
                    final_image[y, x] = slices[z, y, x]
                end
            end
        end
    end

    return final_image
end


