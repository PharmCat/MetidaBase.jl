# Metida
# Copyright © 2019-2020 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>

__precompile__(true)
module MetidaBase

    using Tables, PrettyTables#, Reexport

    #@reexport using StatsModels

    import StatsModels: StatisticalModel
    import Tables: istable, columnaccess, columns, getcolumn, columnnames

    import Base: getindex, length, ht_keyindex, show, pushfirst!, iterate, size

    include("abstracttype.jl")
    include("types.jl")
    include("utils.jl")
    include("iterators.jl")

end
