#abstrcattype.jl

# Metida.jl

abstract type MetidaModel <: StatisticalModel end

abstract type AbstractCovarianceStructure end

abstract type AbstractCovmatMethod end

abstract type AbstractCovarianceType end

abstract type AbstractLMMDataBlocks end

# Data

abstract type AbstractData end

# All have field: id::Dict
abstract type AbstractIdData <: AbstractData end

# All have field:  result::Dict
abstract type AbstractResultData <: AbstractData end

function Base.getindex(a::T, s::Symbol) where T <: AbstractResultData
    return a.result[s]
end

# All have field: result::Dict, data::AbstractIdData
abstract type  AbstractIDResult{AbstractIdData} <: AbstractResultData end


# MetidaFreq.jl

# MetidaNCA.jl
# All have fields: time::Vector, obs::Vector, id::Dict
abstract type AbstractSubject <: AbstractIdData end

# All have field: result::Dict, data::AbstractSubject
#abstract type AbstractSubjectResult{AbstractSubject} <: AbstractResultData end
abstract type AbstractSubjectResult{AbstractSubject} <: AbstractIDResult{AbstractSubject} end


# Descript

#=
struct IdData{T, K, V} <: AbstractIdData
    obs::T
    id::Dict{K, V}
end


struct Descriptives{T} <: AbstractIDResult{T}
    subject::T
    result::Dict
end
=#
