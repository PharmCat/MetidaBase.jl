# MetidaBase.jl
struct MetidaTable{T <: NamedTuple}
    table::T
end

"""
    metida_table(table::NamedTuple)

Make MetidaTable from NamedTuple.
"""
function metida_table(table::NamedTuple)
    MetidaTable(table)
end

"""
    metida_table(args...; kwargs...)

Make MetidaTable.

For AbstractIDResult:

    metida_table(obj::DataSet{RD}; order = nothing, results = nothing, ids = nothing)

Where obj <: DataSet{<:AbstractIDResult}
order - order of columns (Vector of column's names);
results - result columns;
ids - ID's columns;
"""
function metida_table(args...; kwargs...)
    MetidaTable(metida_table_(args...; kwargs...))
end
function metida_table_(args...; names = nothing)
    if length(args) > 1
        e1 = length(args[1])
        i = 2
        @inbounds for i = 2:length(args)
            length(args[i]) == e1 || error("Length not equal")
        end
    end
    if isnothing(names)
        names = Tuple(Symbol.(:x , Symbol.(collect(1:length(args)))))
    else
        if length(args) != length(names) error("Length args and names not equal") end
        if !(typeof(names) <: Tuple)
            if !(typeof(names) <: AbstractVector{Symbol})
                names = Tuple(Symbol.(names))
            else
                names = Tuple(names)
            end
        end
    end
    NamedTuple{names}(args)
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

Tables.schema(t::MetidaTable) = Tables.Schema(names(t), eltype(y) for y in t.table)

################################################################################
# BASE
################################################################################

Base.names(t::MetidaTable) = collect(keys(t.table))

function Base.getindex(t::MetidaTable, col::Colon, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)
end
function Base.getindex(t::MetidaTable, col::Colon, inds::AbstractVector{T}) where T <: Union{Symbol, Int}
    if T <: Int
        names = columnnames(t)[inds]
    else
        names = inds
    end
    cols = map(c->Tables.getcolumn(t, c), inds)
    MetidaTable(metida_table_(cols...; names = names))
end

function Base.getindex(t::MetidaTable, r::Int, ::Colon)
    MetidaTableRow(r, t)
    #NamedTuple{keys(t.table)}(tuple(Iterators.map(c -> getindex(t, r, c), keys(t.table))...))
end


function Base.getindex(t::MetidaTable, row::Int, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)[row]
end

function Base.setindex!(t::MetidaTable, val, row::Int, ind::T) where T <: Union{Symbol, Int}
    Tables.getcolumn(t, ind)[row] = val
end

function Base.append!(t::MetidaTable, t2::MetidaTable)
    if !(names(t) ⊆ names(t2)) error("Names for t not in t2") end
    for n in names(t)
        append!(t[:, n], t2[:, n])
    end
    t
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
    pretty_table(io, table; table_format = TextTableFormat(borders = text_table_borders__compact))
end
function Base.show(io::IO, row::MetidaTableRow)
    print(io, "Row: (")
    names = keys(table(getfield(row, :source)))
    print(io, names[1], " = ", row[names[1]])
    if length(names) > 1
        for i = 2:length(names)
            print(io, ", ", names[i], " = ", row[names[i]])
        end
    end
    print(io, ")")
end