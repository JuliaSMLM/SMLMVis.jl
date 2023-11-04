using Images

sz = 1000
rgb = Matrix{RGB{Float32}}(undef, sz, sz)
arr = Matrix{Float32}(undef, sz, sz)

@time begin
    for idx in eachindex(rgb)
        rgb[idx] .= RGB{Float32, 1,1,1}
    end
end

@time begin
    for idx in eachindex(rgb)
        arr[idx] .= Float32(1)
    end
end

