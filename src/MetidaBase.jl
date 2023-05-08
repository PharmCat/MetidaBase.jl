# Metida
# Copyright © 2019-2020 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>
module MetidaBase

    using Tables, PrettyTables, StatsModels, CategoricalArrays, Requires#, Reexport

    import StatsBase
    import StatsModels: StatisticalModel, RegressionModel
    import Tables: istable, columnaccess, columns, getcolumn, columnnames, schema, rowaccess, rows
    import CPUSummary: num_cores

    import Base: getindex, length, ht_keyindex, show, pushfirst!, iterate, size, findfirst, push!, append!

    include("abstracttype.jl")
    include("m_tables.jl")
    include("dataset.jl")
    include("types.jl")
    include("utils.jl")
    include("iterators.jl")
    include("precompile.jl")

    function __init__()
        @require DataFrames="a93c6f00-e57d-5684-b7b6-d8193f3e46c0" include("dataframes.jl")
        @require TypedTables="9d95f2ec-7b3d-5a63-8d20-e2491e220bb9" include("typedtables.jl")
    end

end
