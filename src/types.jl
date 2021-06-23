
# MetidaBase.jl

struct MetidaTable{T <: NamedTuple}
    table::T
end

Tables.istable(t::MetidaTable) = true

Tables.columnaccess(t::MetidaTable) = true

Tables.columns(t::MetidaTable) = t

Tables.getcolumn(t::MetidaTable, i::Int) = t.table[i]

Tables.getcolumn(t::MetidaTable, nm::Symbol) = t.table[nm]

Tables.columnnames(t::MetidaTable) = collect(keys(t.table))

# All

struct DataSet{T <: AbstractData}
    data::Vector{T}
end

function Base.getindex(ds::DataSet, ind)
    ds.data[ind]
end

function Base.length(ds::DataSet)
    length(ds.data)
end

function getindormiss(d, i)
    ind = ht_keyindex(d, i)
    if ind > 0 return d.vals[ind]  else return missing  end
end
function islessdict(a::Dict{A1,A2}, b::Dict{B1,B2}, k::Union{AbstractVector, Set}) where A1 where A2 where B1 where B2
    l = length(k)
    av = Vector{Union{Missing, A2}}(undef, l)
    bv = Vector{Union{Missing, B2}}(undef, l)
    @inbounds for i = 1:l
        av[i] = getindormiss(a, k[i])
        bv[i] = getindormiss(b, k[i])
    end
    isless(av, bv)
end
function islessdict(a::Dict, b::Dict, k)
    isless(getindormiss(a, k), getindormiss(b, k))
end
function Base.sort!(a::DataSet{T}, k; alg::Base.Algorithm = QuickSort, lt=nothing, by=nothing, rev::Bool=false, order::Base.Ordering = Base.Forward) where T <: AbstractIdData
    if isnothing(by) by = x -> x.id end
    if isnothing(lt) lt = (x, y) -> islessdict(x, y, k) end
    sort!(a.data;  alg = alg, lt = lt, by = by, rev = rev, order = order)
    a
end

# MetidaFreq.jl

struct Proportion <: AbstractData
    x::Int
    n::Int
end
