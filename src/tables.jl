# TypedTables.jl interface
function TypedTables.Table(obj::AbstractDataSet; kwargs...)
    TypedTables.Table(metida_table_(obj; kwargs...))
end
function TypedTables.Table(obj::MetidaTable)
    TypedTables.Table(obj.table)
end

# DataFrames.jl interface
function DataFrames.DataFrame(obj::AbstractDataSet; kwargs...)
    DataFrames.DataFrame(metida_table_(obj; kwargs...))
end

function DataFrames.DataFrame(obj::MetidaTable)
    DataFrames.DataFrame(obj.table)
end