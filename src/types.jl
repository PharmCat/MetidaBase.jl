
# MetidaBase.jl

struct MetidaTable{T <: NamedTuple}
    table::T
end

function metida_table(args...; names = nothing)
    if length(args) > 1
        e1 = length(args[1])
        i = 2
        @inbounds for i = 2:length(args)
            length(args[i]) == e1 || error("Length not equal")
        end
    end
    if isnothing(names)
        names = Tuple(Symbol.("x" .* string.(collect(1:length(args)))))
    else
        if length(args) != length(names) error("Length args and names not equal") end
        if !(typeof(names) <: Tuple)
            names = Tuple(names)
        end
    end
    MetidaBase.MetidaTable(NamedTuple{names}(args))
end
################################################################################
# TABLES
################################################################################
Tables.istable(t::MetidaTable) = true

Tables.columnaccess(t::MetidaTable) = true

Tables.columns(t::MetidaTable) = t

Tables.getcolumn(t::MetidaTable, i::Int) = t.table[i]

Tables.getcolumn(t::MetidaTable, nm::Symbol) = t.table[nm]

Tables.getcolumn(t::MetidaTable, ::Type{T}, col::Int, nm::Symbol) where {T} = t[:, col]

Tables.columnnames(t::MetidaTable) = collect(keys(t.table))

################################################################################
# BASE
################################################################################
function Base.getindex(t::MetidaTable, col::Colon, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)
end
function Base.getindex(t::MetidaTable, row::Int, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)[row]
end

function Base.setindex!(t::MetidaTable, val, row::Int, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)[row] = val
end

function Base.pushfirst!(t::MetidaTable, row::AbstractVector)
    if length(row) != length(keys(t.table)) error("Size not equal") end
    i = 1
    for i = 1:length(row)
        pushfirst!(t.table[i], row[i])
    end
    t
end
function Base.pushfirst!(t::MetidaTable, row::NamedTuple)
    kt = keys(t.table)
    kr = keys(row)
    if !issetequal(kt, kr) error("Size not equal") end
    for i in kt
        pushfirst!(t.table[i], row[i])
    end
    t
end

function Base.show(io::IO, table::MetidaTable)
    pretty_table(io, table; tf = PrettyTables.tf_compact)
end

# All
################################################################################
# DATASET
################################################################################
struct DataSet{T <: AbstractData}
    ds::Vector{T}
end

function getdata(d::DataSet)
    d.ds
end
@inline function getindormiss(d::Dict{K}, i::K) where K
    ind::Int = ht_keyindex(d, i)
    if ind > 0 return d.vals[ind]  end
    missing
end
################################################################################
# BASE
################################################################################

function Base.getindex(d::DataSet, ind::Int)
    d.ds[ind]
end
@inline function getresultindex_safe(rd::T, ind::Symbol) where T <: AbstractResultData
    getindormiss(rd.result, ind)
end
@inline function getresultindex_unsafe(rd::T, ind::Symbol) where T <: AbstractResultData
    rd.result[ind]
end

#@inline function getresultindex(subj, ind::Symbol)
#    getindormiss(subj.result, ind)
#end

function Base.getindex(d::DataSet{T}, col::Int, ind) where T <: AbstractResultData
    getresultindex_safe(d[col], ind)
end
function Base.getindex(d::DataSet{T}, col::Colon, ind) where T <: AbstractResultData
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].result, ind) < 1 return getresultindex_safe.(d.ds, ind) end
    end
    getresultindex_unsafe.(d.ds, ind)
    #getresultindex.(ds.data, ind)
end

Base.first(d::DataSet) = first(d.ds)

function Base.length(d::DataSet)
    length(d.ds)
end

function Base.iterate(d::DataSet)
    return Base.iterate(d.ds)
end
function Base.iterate(d::DataSet, i::Int)
    return Base.iterate(d.ds, i)
end

################################################################################
# BASE.SORT
################################################################################
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
function Base.sort!(d::DataSet{T}, k; alg::Base.Algorithm = QuickSort, lt=nothing, by=nothing, rev::Bool=false, order::Base.Ordering = Base.Forward) where T <: Union{AbstractIdData, AbstractIDResult}
    if isnothing(by) by = x -> getid(x) end
    if isnothing(lt) lt = (x, y) -> islessdict(x, y, k) end
    sort!(d.ds;  alg = alg, lt = lt, by = by, rev = rev, order = order)
    d
end

################################################################################
# SELF
################################################################################

getid_safe(idd::AbstractIdData, ind) = getindormiss(idd.id, ind)

getid_unsafe(idd::AbstractIdData, ind) = idd.id[ind]

getid_safe(asr::AbstractSubjectResult, ind) = getindormiss(asr.data.id, ind)

getid_unsafe(asr::AbstractSubjectResult, ind) = asr.data.id[ind]

getid(idd::AbstractIdData, ind) = getid_safe(idd, ind)

getid(asr::AbstractSubjectResult, ind) = getid_safe(asr, ind)

getid(idd::AbstractIdData) = idd.id

getid(asr::AbstractSubjectResult) = asr.data.id

function getid(d::DataSet{T}, col::Int, ind) where T <: Union{AbstractIdData, AbstractSubjectResult}
    getid(d[col], ind)
end
function getid(d::DataSet{T}, col::Colon, ind) where T <: AbstractIdData
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].id, ind) < 1 return getid_safe.(d.ds, ind) end
    end
    getid_unsafe.(d.ds, ind)
end
function getid(d::DataSet{T}, col::Colon, ind) where T <: AbstractSubjectResult
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].data.id, ind) < 1 return getid_safe.(d.ds, ind) end
    end
    getid_unsafe.(d.ds, ind)
end


function uniqueidlist(d::DataSet{T}, list::AbstractVector{Symbol}) where T <: AbstractIdData
    dl = Vector{Dict}(undef, 0)
    for i in d
        if list ⊆ keys(i.id)
            subd = Dict(k => i.id[k] for k in list)
            if subd ∉ dl push!(dl, subd) end
        end
    end
    dl
end
function uniqueidlist(d::DataSet{T}, list::Symbol) where T <: AbstractIdData
    dl = Vector{Dict}(undef, 0)
    for i in d
        if list in keys(i.id)
            subd = Dict(list => i.id[list])
            if subd ∉ dl push!(dl, subd) end
        end
    end
    dl
end

function subset(d::DataSet, sort::Dict)
    inds = findall(x-> sort ⊆ x.id, d.ds)
    if length(inds) > 0 return DataSet(d.ds[inds]) end
    nothing
end
################################################################################

# MetidaFreq.jl

struct Proportion <: AbstractData
    x::Int
    n::Int
end
