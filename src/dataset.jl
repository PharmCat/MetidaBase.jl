################################################################################
# DATASET
################################################################################
struct DataSet{T <: AbstractData} <: AbstractDataSet{AbstractData}
    ds::Vector{T}
    metadata::Dict
    function DataSet(ds::AbstractVector{T}, metadata::Dict) where T <: AbstractData
        new{T}(ds, metadata)::DataSet
    end
    function DataSet(ds)
        DataSet(ds, Dict{Symbol, Any}())
    end
end

function getdata(d::DataSet)
    d.ds
end

@inline function getindormiss(d::AbstractDict{K}, i::K) where K
    if haskey(d, i) return d[i]  end
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

Base.getindex(d::DataSet, inds) = subset(d, inds)


@inline function getresultindex_safe(rd::T, ind::Symbol) where T <: AbstractResultData
    getindormiss(rd.result, ind)
end
@inline function getresultindex_unsafe(rd::T, ind::Symbol) where T <: AbstractResultData
    rd.result[ind]
end
getresultindex_safe(rd, ind::AbstractString)   = getresultindex_safe(rd, Symbol(ind))
getresultindex_unsafe(rd, ind::AbstractString) = getresultindex_unsafe(rd, Symbol(ind))

function Base.getindex(d::DataSet{T}, col::Int, ind) where T <: AbstractResultData
    getresultindex_safe(d[col], ind)
end
function Base.getindex(d::DataSet{T}, col::Colon, ind) where T <: AbstractResultData
    @inbounds for i in Base.OneTo(length(d))
        if !haskey(d.ds[i].result, ind) return getresultindex_safe.(d.ds, ind) end
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

function Base.push!(d::DataSet, el)
    push!(getdata(d), el)
end

function Base.append!(d::DataSet, d2::DataSet)
    append!(getdata(d), getdata(d2))
end

function Base.append!(d::DataSet, el)
    append!(getdata(d), el)
end


################################################################################
# BASE
################################################################################
# sort!
################################################################################
function islessdict(a::AbstractDict{A1,A2}, b::AbstractDict{B1,B2}, k::Union{AbstractVector, Set}) where A1 where A2 where B1 where B2
    l = length(k)
    av = Vector{Union{Missing, A2}}(undef, l)
    bv = Vector{Union{Missing, B2}}(undef, l)
    @inbounds for i = 1:l
        av[i] = getindormiss(a, k[i])
        bv[i] = getindormiss(b, k[i])
    end
    isless(av, bv)
end
function islessdict(a::AbstractDict, b::AbstractDict, k)
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
    DataSet(filter(f, getdata(d)))
end
function Base.filter!(f::Function, d::DataSet)
    filter!(f, getdata(d))
    d
end

function Base.filter(f::Dict{:Symbol, Function}, d::DataSet)
    k = keys(f)
    a = filter(x -> f[first(k)](getid(x, first(k))), getdata(d))
    if length(k) > 1
        for kn = 2:length(k)
            filter!(x -> f[k[kn]](getid(x, k[kn])), a)
        end
    end
    DataSet(a)
end
function Base.filter!(f::Dict{:Symbol, Function}, d::DataSet)
    for k in keys(f)
        filter!(x -> f[k](getid(x, k)), getdata(d))
    end
    d
end

################################################################################
# Base.findfirst
################################################################################

function Base.findfirst(d::DataSet{<: AbstractIdData}, sort::Dict)
    findfirst(x-> sort ⊆ getid(x), getdata(d))
end

################################################################################
# Base.findlast
################################################################################

function Base.findlast(d::DataSet{<: AbstractIdData}, sort::Dict)
    findlast(x-> sort ⊆ getid(x), getdata(d))
end

################################################################################
# Base.findnext
################################################################################

function Base.findnext(d::DataSet{<: AbstractIdData}, sort::Dict, i::Int)
    findnext(x-> sort ⊆ getid(x), getdata(d), i)
end


################################################################################
# Base.findprev 
################################################################################

function Base.findprev(d::DataSet{<: AbstractIdData}, sort::Dict, i::Int)
    findprev(x-> sort ⊆ getid(x), getdata(d), i)
end

################################################################################
# Base.findall 
################################################################################

function Base.findall(d::DataSet{<: AbstractIdData}, sort::Dict)
    findall(x-> sort ⊆ getid(x), getdata(d))
end

################################################################################
# find*el
################################################################################

function findfirstel(d::DataSet{<: AbstractIdData}, sort::Dict)
    ind = findfirst(x-> sort ⊆ getid(x), getdata(d))
    if isnothing(ind)
        return nothing
    else
        return d[ind]
    end
end
function findlastel(d::DataSet{<: AbstractIdData}, sort::Dict)
    ind = findlast(x-> sort ⊆ getid(x), getdata(d))
    if isnothing(ind)
        return nothing
    else
        return d[ind]
    end
end
function findnextel(d::DataSet{<: AbstractIdData}, sort::Dict, i::Int)
    ind = findnext(x-> sort ⊆ getid(x), getdata(d), i)
    if isnothing(ind)
        return nothing
    else
        return d[ind]
    end
end
function findprevel(d::DataSet{<: AbstractIdData}, sort::Dict, i::Int)
    ind = findprev(x-> sort ⊆ getid(x), getdata(d), i)
    if isnothing(ind)
        return nothing
    else
        return d[ind]
    end
end
function findallel(d::DataSet{<: AbstractIdData}, sort::Dict)
    ind = findall(x-> sort ⊆ getid(x), getdata(d))
    if isnothing(ind)
        return nothing
    else
        return d[ind]
    end
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
        if !haskey(d.ds[i].id, ind) return getid_safe.(d.ds, ind) end
    end
    getid_unsafe.(d.ds, ind)
end
function getid(d::DataSet{T}, col::Colon, ind) where T <: AbstractIDResult
    @inbounds for i in Base.OneTo(length(d))
        if !haskey(d.ds[i].data.id, ind) return getid_safe.(d.ds, ind) end
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
