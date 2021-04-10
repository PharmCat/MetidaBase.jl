
# MetidaFreq.jl

struct DataSet{T <: AbstractData}
    data::AbstractVector{T}
end

function Base.getindex(ds::DataSet, ind)
    ds.data[ind]
end

struct Proportion <: AbstractData
    p::Rational{Int64}
end
