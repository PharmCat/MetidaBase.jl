
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

function Base.show(io::IO, table::MetidaTable)
    pretty_table(io, table)
end

# All

struct DataSet{T <: AbstractData}
    data::Vector{T}
end

function Base.getindex(ds::DataSet, ind::Int)
    ds.data[ind]
end
Base.first(ds::DataSet) = first(ds.data)

function Base.getindex(ds::DataSet{T}, col::Colon, ind) where T <: AbstractResultData
    v = Vector{Float64}(undef, length(ds))
    @inbounds for i = 1:length(ds)
        v[i] = getindormiss(ds[i].result, ind)
    end
    v
end

function Base.getindex(ds::DataSet{T}, col::Int, ind) where T <: AbstractResultData
    getindormiss(ds[col].result, ind)
end

function getid(ds::DataSet{T}, col::Colon, ind) where T <: AbstractIdData
    v = Vector{Any}(undef, length(ds))
    @inbounds for i = 1:length(ds)
        v[i] = getindormiss(ds[i].id, ind)
    end
    v
end

function getid(ds::DataSet{T}, col::Int, ind) where T <: AbstractIdData
    getindormiss(ds[col].id, ind)
end



function Base.length(ds::DataSet)
    length(ds.data)
end

function getindormiss(d::Dict{K, V}, i::K)::Union{V, Missing} where K where V
    ind::Int = ht_keyindex(d, i)
    if ind > 0 return d.vals[ind]  end
    missing
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
