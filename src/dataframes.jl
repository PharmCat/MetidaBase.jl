# DataFrames.jl interface
function DataFrames.DataFrame(obj::AbstractDataSet; kwargs...)
    DataFrames.DataFrame(metida_table_(obj; kwargs...))
end

function DataFrames.DataFrame(obj::MetidaTable)
    DataFrames.DataFrame(obj.table)
end