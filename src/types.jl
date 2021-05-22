
# MetidaBase.jl

struct MetidaTable{T <: NamedTuple}
    table::T
end

Tables.istable(t::MetidaTable) = true

Tables.columnaccess(t::MetidaTable) = true

Tables.columns(t::MetidaTable) = t

Tables.getcolumn(t, i::Int) = t.table[i]

Tables.getcolumn(t, nm::Symbol) = t.table[nm]

Tables.columnnames(t::MetidaTable) = collect(keys(t.table))


# MetidaFreq.jl

struct DataSet{T <: AbstractData}
    data::Vector{T}
end

function Base.getindex(ds::DataSet, ind)
    ds.data[ind]
end

function Base.length(ds::DataSet)
    length(ds.data)
end

struct Proportion <: AbstractData
    x::Int
    n::Int
end
