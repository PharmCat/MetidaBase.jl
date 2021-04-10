# Metida
# Copyright © 2019-2020 Vladimir Arnautov aka PharmCat <mail@pharmcat.net>

__precompile__()
module MetidaBase

    using StatsModels

    import Base: getindex

    include("abstracttype.jl")
    include("types.jl")

end
