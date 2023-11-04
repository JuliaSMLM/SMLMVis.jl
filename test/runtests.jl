using SMLMVis
using Test
using HDF5

@testset "SMLMVis.jl" begin
    # Write your tests here.

    @testset "MIC" begin
        groupname = "Channel01/Zposition001/Data0001"
        h5open("example.h5", "w") do fid
            g = create_group(fid, groupname)
            dset = create_dataset(g, "Data0001", UInt16, (100, 100, 10,))
            write(dset, rand(UInt16, 100, 100, 10))
        end
        SMLMVis.MIC.mic2mp4("example.h5")
        @test isfile("example.mp4") 
        isfile("example.mp4") && rm("example.mp4")
    end

    @testset "render_blobs" begin
        # Test rendering a single blob
        x_range = (1, 100)
        y_range = (1, 100)
        x = [50]
        y = [50]
        σ_x = [10]
        σ_y = [10]
        img = render_blobs(x_range, y_range, x, y, σ_x, σ_y)
        @test size(img) == (100, 100)
    
    end
end
