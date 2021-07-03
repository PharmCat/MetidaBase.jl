# Metida
# Copyright © 2019-2020 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>

__precompile__(true)
module MetidaBase

    using Tables, StatsModels

    import Tables: istable, columnaccess, columns, getcolumn, columnnames

    import StatsModels: StatisticalModel

    import Base: getindex, length, ht_keyindex

    include("abstracttype.jl")
    include("types.jl")

end
