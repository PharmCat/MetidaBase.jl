#abstrcattype.jl

# Metida.jl

abstract type MetidaModel <: StatisticalModel end

abstract type AbstractCovarianceStructure end

abstract type AbstractCovmatMethod end

abstract type AbstractCovarianceType end

abstract type AbstractLMMDataBlocks end

# Data

abstract type AbstractData end

abstract type AbstractResultData <: AbstractData end

# All have field: id::Dict
abstract type AbstractIdData <: AbstractData end

# MetidaFreq.jl


# MetidaNCA.jl
# All have fields: time::Vector, obs::Vector
#
#
abstract type AbstractSubject <: AbstractIdData end
