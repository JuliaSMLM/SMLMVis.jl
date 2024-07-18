module PhysicalArrays

using Base: @propagate_inbounds

export PhysicalArray, physical_value, index_value

struct PhysicalArray{T,N,A<:AbstractArray{T,N}} <: AbstractArray{T,N}
    data::A
    ranges::NTuple{N,Tuple{Float64,Float64}}
    scales::NTuple{N,Float64}
    offsets::NTuple{N,Float64}
end

# Constructor
function PhysicalArray(data::AbstractArray{T,N}, ranges::NTuple{N,Tuple{Float64,Float64}}) where {T,N}
    scales = ntuple(i -> (ranges[i][2] - ranges[i][1]) / (size(data, i) - 1), N)
    offsets = ntuple(i -> ranges[i][1], N)
    PhysicalArray{T,N,typeof(data)}(data, ranges, scales, offsets)
end

# New constructor that takes mixed range types
function PhysicalArray(ranges::Vararg{AbstractRange})
    N = length(ranges)
    sizes = map(length, ranges)
    data = zeros(Float64, sizes...)
    
    range_tuples = map(ranges) do r
        T = eltype(r)
        if T <: Integer
            (Float64(first(r)), Float64(last(r)))
        else
            (first(r), last(r))
        end
    end
    
    scales = map(ranges) do r
        T = eltype(r)
        if T <: Integer
            Float64(step(r))
        else
            step(r)
        end
    end
    
    offsets = map(ranges) do r
        T = eltype(r)
        if T <: Integer
            Float64(first(r))
        else
            first(r)
        end
    end
    
    PhysicalArray{Float64,N,typeof(data)}(data, range_tuples, scales, offsets)
end


# Array interface
Base.size(A::PhysicalArray) = size(A.data)
Base.getindex(A::PhysicalArray, I::Int...) = A.data[I...]
Base.setindex!(A::PhysicalArray, v, I::Int...) = (A.data[I...] = v)

# Convert from index to physical value
@inline function physical_value(A::PhysicalArray{T,N}, I::Vararg{Int,N}) where {T,N}
    return ntuple(i -> A.offsets[i] + A.scales[i] * (I[i] - 1), N)
end

# Convert from physical value to index
@inline function index_value(A::PhysicalArray{T,N}, P::Vararg{Float64,N}) where {T,N}
    return ntuple(i -> round(Int, (P[i] - A.offsets[i]) / A.scales[i] + 1), N)
end

# Custom indexing to allow for physical value indexing
@propagate_inbounds function Base.getindex(A::PhysicalArray{T,N}, I::Vararg{Union{Int,Float64},N}) where {T,N}
    idx = map((i, scale, offset) -> 
        isa(i, Float64) ? round(Int, (i - offset) / scale + 1) : i, 
        I, A.scales, A.offsets)
    return A.data[idx...]
end

# Overload getindex to support range-based indexing
function Base.getindex(A::PhysicalArray{T,N}, I::Vararg{Union{Int,AbstractRange{Int}},N}) where {T,N}
    # Check if we're doing regular indexing or subarray creation
    if all(x -> x isa Int, I)
        return A.data[I...]
    end
    
    # Calculate new ranges, data, scales, and offsets
    new_ranges = ntuple(N) do i
        if I[i] isa AbstractRange
            start_val, end_val = physical_value(A, first(I[i]), last(I[i]))
            (start_val, end_val)
        else
            val = physical_value(A, I[i])[i]
            (val, val)
        end
    end
    
    new_data = A.data[I...]
    new_scales = A.scales
    new_offsets = ntuple(i -> new_ranges[i][1], N)
    
    return PhysicalArray{T,ndims(new_data),typeof(new_data)}(new_data, new_ranges, new_scales, new_offsets)
end



@propagate_inbounds function Base.setindex!(A::PhysicalArray{T,N}, v, I::Vararg{Union{Int,Float64},N}) where {T,N}
    idx = map((i, scale, offset) -> 
        isa(i, Float64) ? round(Int, (i - offset) / scale + 1) : i, 
        I, A.scales, A.offsets)
    A.data[idx...] = v
end

# Overload setindex! to support both single-element and subarray assignment
function Base.setindex!(A::PhysicalArray{T,N}, v, I::Vararg{Union{Int,AbstractRange{Int}},N}) where {T,N}
    if all(x -> x isa Int, I)
        # Single element assignment
        A.data[I...] = v
    elseif v isa PhysicalArray
        # Subarray assignment from another PhysicalArray
        target_indices = map(i -> i isa AbstractRange ? i : (i:i), I)
        source_indices = map(d -> 1:size(v, d), 1:N)
        A.data[target_indices...] .= v.data[source_indices...]
    else
        # Subarray assignment from a regular array or scalar
        A.data[I...] = v
    end
    return A
end

# Pretty printing
function Base.show(io::IO, ::MIME"text/plain", A::PhysicalArray)
    println(io, "PhysicalArray with ranges:")
    for (i, range) in enumerate(A.ranges)
        println(io, "  Dimension $i: $(range[1]) to $(range[2]) ($(size(A.data, i)) points)")
    end
    println(io, "and data:")
    show(io, MIME"text/plain"(), A.data)
end

end # module

