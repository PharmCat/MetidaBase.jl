# TypedTables.jl interface
function TypedTables.Table(obj::AbstractDataSet; kwargs...)
    TypedTables.Table(metida_table_(obj; kwargs...))
end
function TypedTables.Table(obj::MetidaTable)
    TypedTables.Table(obj.table)
end