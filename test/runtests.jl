using SMLMVis
using Test

@testset "SMLMVis.jl" begin
    # Write your tests here.


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
