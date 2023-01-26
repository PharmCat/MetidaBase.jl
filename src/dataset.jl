################################################################################
# DATASET
################################################################################
struct DataSet{T <: AbstractData} <: AbstractDataSet{AbstractData}
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

Tables.istable(::AbstractDataSet) = false

Tables.rowaccess(::AbstractDataSet) = false
################################################################################
# BASE
################################################################################

function Base.getindex(d::DataSet, ind::Int)
    d.ds[ind]
end

Base.getindex(d::DataSet, inds::UnitRange{Int64}) = subset(d, inds)


@inline function getresultindex_safe(rd::T, ind::Symbol) where T <: AbstractResultData
    getindormiss(rd.result, ind)
end
@inline function getresultindex_unsafe(rd::T, ind::Symbol) where T <: AbstractResultData
    rd.result[ind]
end

function Base.getindex(d::DataSet{T}, col::Int, ind) where T <: AbstractResultData
    getresultindex_safe(d[col], ind)
end
function Base.getindex(d::DataSet{T}, col::Colon, ind) where T <: AbstractResultData
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].result, ind) < 1 return getresultindex_safe.(d.ds, ind) end
    end
    getresultindex_unsafe.(d.ds, ind)
end

Base.first(d::DataSet) = first(getdata(d))

function Base.length(d::DataSet)
    length(getdata(d))
end

function Base.iterate(d::DataSet)
    return Base.iterate(getdata(d))
end

function Base.iterate(d::DataSet, i::Int)
    return Base.iterate(getdata(d), i)
end

function Base.map(f, d::DataSet)
    DataSet(map(f, getdata(d)))
end

################################################################################
# BASE
################################################################################
# sort!
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
# filter
# filter!
################################################################################
function Base.filter(f::Function, d::DataSet)
    ds   =  getdata(d)
    inds  = findall(f, ds)
    DataSet(ds[inds])
end
function Base.filter!(f::Function, d::DataSet)
    filter!(f, getdata(d))
    d
end

################################################################################
# Base.findfirst
################################################################################

function Base.findfirst(d::DataSet{<: AbstractIdData}, sort::Dict)
    findfirst(x-> sort ⊆ getid(x), getdata(d))
end

################################################################################
# SELF
################################################################################

getid_safe(idd::AbstractIdData, ind) = getindormiss(idd.id, ind)

getid_unsafe(idd::AbstractIdData, ind) = idd.id[ind]

getid_safe(asr::AbstractIDResult, ind) = getindormiss(asr.data.id, ind)

getid_unsafe(asr::AbstractIDResult, ind) = asr.data.id[ind]

getid(idd::AbstractIdData, ind) = getid_safe(idd, ind)

getid(asr::AbstractIDResult, ind) = getid_safe(asr, ind)

getid(idd::AbstractIdData) = idd.id

getid(asr::AbstractIDResult) = asr.data.id

function getid(d::DataSet{T}, col::Int, ind) where T <: Union{AbstractIdData, AbstractIDResult}
    getid(d[col], ind)
end
function getid(d::DataSet{T}, col::Colon, ind) where T <: AbstractIdData
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].id, ind) < 1 return getid_safe.(d.ds, ind) end
    end
    getid_unsafe.(d.ds, ind)
end
function getid(d::DataSet{T}, col::Colon, ind) where T <: AbstractIDResult
    @inbounds for i in Base.OneTo(length(d))
        if Base.ht_keyindex(d.ds[i].data.id, ind) < 1 return getid_safe.(d.ds, ind) end
    end
    getid_unsafe.(d.ds, ind)
end


function uniqueidlist(d::DataSet{T}, list::AbstractVector{Symbol}) where T <: AbstractIdData
    dl = Vector{Dict}(undef, 0)
    for i in d
        if list ⊆ keys(getid(i))
            subd = Dict(k => getid(i)[k] for k in list)
            if subd ∉ dl push!(dl, subd) end
        end
    end
    dl
end

function uniqueidlist(d::DataSet{T}, list::Symbol) where T <: AbstractIdData
    dl = Vector{Dict}(undef, 0)
    for i in d
        if list in keys(getid(i))
            subd = Dict(list => getid(i)[list])
            if subd ∉ dl push!(dl, subd) end
        end
    end
    dl
end
#=
function uniqueidlist(d::DataSet{T}) where T <: AbstractIdData
    dl = Vector{Dict}(undef, 0)
    for i in d
        id = getid(i)
        if id ∉ dl push!(dl, id) end
    end
    dl
end
=#
function uniqueidlist(::DataSet{T}, ::Nothing) where T <: AbstractIdData
    nothing
end


function subset(d::DataSet{T}, sort::Dict) where T <: AbstractIdData
    inds = findall(x-> sort ⊆ getid(x), getdata(d))
    if length(inds) > 0 return DataSet(getdata(d)[inds]) end
    DataSet(Vector{T}(undef, 0))
end
function subset(d::DataSet{T}, sort::Dict) where T <: AbstractIDResult
    inds = findall(x-> sort ⊆ getid(x), getdata(d))
    if length(inds) > 0 return DataSet(getdata(d)[inds]) end
    DataSet(Vector{T}(undef, 0))
end
function subset(d::DataSet, inds)
    DataSet(getdata(d)[inds])
end
################################################################################
# metida_table from DataSet{AbstractIDResult}
################################################################################
function metida_table_(obj::DataSet{RD}; order = nothing, results = nothing, ids = nothing) where RD <: AbstractIDResult
    idset  = Set(keys(first(obj).data.id))
    resset = Set(keys(first(obj).result))
    if length(obj) > 1
        for i = 2:length(obj)
            union!(idset,  Set(keys(obj[i].data.id)))
            union!(resset, Set(keys(obj[i].result)))
        end
    end
    if !isnothing(results)
        if isa(results, Symbol) results = [results] end
        if isa(results, String) results = [Symbol(results)] end
        ressetl = isnothing(order) ? collect(intersect(resset, results)) : sortbyvec!(collect(intersect(resset, results)), order)
    else
        ressetl = isnothing(order) ? collect(resset) : sortbyvec!(collect(resset), order)
    end
    if !isnothing(ids)
        if isa(ids, Symbol) ids = [ids] end
        if isa(ids, String) ids = [Symbol(ids)] end
        ids ⊆ idset || error("Some id not in dataset!")
        idset = intersect(idset, ids)
    end
    mt1 = metida_table_((getid(obj, :, c) for c in idset)...; names = idset)
    mt2 = metida_table_((obj[:, c] for c in ressetl)...; names = ressetl)
    merge(mt1, mt2)
end
################################################################################
