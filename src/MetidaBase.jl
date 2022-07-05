# Metida
# Copyright © 2019-2020 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>

__precompile__(true)
module MetidaBase

    using Tables, PrettyTables, TypedTables, StatsBase, StatsModels#, Reexport

    #@reexport using StatsModels

    import StatsModels: StatisticalModel
    import Tables: istable, columnaccess, columns, getcolumn, columnnames, schema, rowaccess, rows
    import CPUSummary: num_cores

    import Base: getindex, length, ht_keyindex, show, pushfirst!, iterate, size, findfirst

    include("abstracttype.jl")
    include("types.jl")
    include("utils.jl")
    include("iterators.jl")

end
