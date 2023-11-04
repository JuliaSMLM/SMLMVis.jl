using Revise
using SMLMVis
using OffsetArrays

function testwrite(a::SMLMVis.GaussRender.RGBArray{Float32},
    rois::Vector{OffsetMatrix{Float32,Matrix{Float32}}})

    for n = 1:length(rois)
        roi::Matrix{Float32} = rois[n].parent  # Explicit type declaration
        y_start::Int, x_start::Int = rois[n].offsets  # Explicit type declaration
        for i = 1:length(rois[n])
            a.r[i] += roi[i]
        end
    end
end

function testwrite(a::Matrix{Float32}, a_offsets,
    rois::Vector{OffsetMatrix{Float32,Matrix{Float32}}})

    box_size = size(rois[1], 1)

    for n = 1:length(rois)
        roi = rois[n].parent
        y_offset, x_offset = rois[n].offsets

        for i in 1:box_size, j in 1:box_size
            # Calculate the actual indices in 'a' where the data should be written.
            actual_i = i + y_offset - a_offsets[1]
            actual_j = j + x_offset - a_offsets[2]

            # Check boundary conditions before writing into 'a'
            if 1 <= actual_i <= size(a, 1) && 1 <= actual_j <= size(a, 2)
                a[actual_i, actual_j] += roi[i, j]
            end
        end
    end
end


box_size = 20
a = SMLMVis.GaussRender.RGBArray{Float32}((512, 512))
n_blobs = 100000
# rois = Vector{OffsetArray{Float32,2}}(undef, n_blobs)
rois = Vector{OffsetArray{Float32,2,Matrix{Float32}}}(undef, n_blobs)


for i in 1:n_blobs
    rois[i] = OffsetArray(zeros(Float32, box_size, box_size))
end

@time testwrite(a, rois)
@code_warntype testwrite(a.r.parent, rois)
@time testwrite(a.r.parent, a.r.offsets, rois)


@code_warntype testwrite(a, rois)

@profview testwrite(a, rois)
