
# MetidaBase.jl

struct MetidaTable{T <: NamedTuple}
    table::T
end
function metida_table(table::NamedTuple)
    MetidaTable(table)
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

table(t::MetidaTable) = getfield(t, :table)
################################################################################
# TABLES
################################################################################
Tables.istable(t::MetidaTable) = true

Tables.columnaccess(t::MetidaTable) = true

Tables.columns(t::MetidaTable) = t

Tables.getcolumn(t::MetidaTable, i::Int) = getfield(t, :table)[i]

Tables.getcolumn(t::MetidaTable, nm::Symbol) = getfield(t, :table)[nm]

Tables.getcolumn(t::MetidaTable, ::Type{T}, col::Int, nm::Symbol) where {T} = t[:, col]

Tables.columnnames(t::MetidaTable) = names(t)

Tables.rowaccess(::Type{<:MetidaTable}) = true
# just return itself, which means MatrixTable must iterate `Tables.AbstractRow`-compatible objects
Tables.rows(t::MetidaTable) = t

# a custom row type; acts as a "view" into a row of an AbstractMatrix
struct MetidaTableRow{T} <: Tables.AbstractRow
    row::Int
    source::MetidaTable{T}
end

Base.iterate(t::MetidaTable, st=1) = st > length(t) ? nothing : (MetidaTableRow(st, t), st + 1)

Tables.getcolumn(t::MetidaTableRow, ::Type, col::Int, nm::Symbol) = getfield(t, :source)[getfield(t, :row), col]

Tables.getcolumn(t::MetidaTableRow, i::Int) = getfield(t, :source)[getfield(t, :row), i]

Tables.getcolumn(t::MetidaTableRow, nm::Symbol) = getfield(t, :source)[getfield(t, :row), nm]

Tables.columnnames(t::MetidaTableRow) = names(getfield(t, :source))

################################################################################
# BASE
################################################################################

Base.names(t::MetidaTable) = collect(keys(t.table))

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

Base.length(t::MetidaTable) = length(first(t.table))

function Base.size(t::MetidaTable, i::Int)
    if i == 1
        return length(first(t.table))
    elseif i == 2
        return length(t.table)
    else
        error("Wrong dimention!")
    end
end

function Base.show(io::IO, table::MetidaTable)
    pretty_table(io, table; tf = PrettyTables.tf_compact)
end

# All
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
    []
end
################################################################################
# metida_table from DataSet{AbstractIDResult}
################################################################################
function metida_table(obj::DataSet{RD}; order = nothing, results = nothing, ids = nothing) where RD <: AbstractIDResult
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
    mt1 = MetidaBase.metida_table((getid(obj, :, c) for c in idset)...; names = idset)
    mt2 = MetidaBase.metida_table((obj[:, c] for c in ressetl)...; names = ressetl)
    MetidaTable(merge(mt1.table, mt2.table))
end
################################################################################
# MetidaFreq.jl

struct Proportion <: AbstractData
    x::Int
    n::Int
end
