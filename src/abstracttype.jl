#abstrcattype.jl

# Metida.jl

abstract type MetidaModel <: RegressionModel  end

abstract type AbstractCovarianceStructure end

abstract type AbstractCovmatMethod end

abstract type AbstractCovarianceType end

abstract type AbstractLMMDataBlocks end

# Data

abstract type AbstractData end

abstract type AbstractDataSet{AbstractData} end

# All have field: id::Dict
abstract type AbstractIdData <: AbstractData end

# All have field:  result::Dict
abstract type AbstractResultData <: AbstractData end

# All have field: result::Dict, data::AbstractIdData
abstract type  AbstractIDResult{AbstractIdData} <: AbstractResultData end

# MetidaFreq.jl

# MetidaNCA.jl
# All have fields: time::Vector, obs::Vector, id::Dict
abstract type AbstractSubject <: AbstractIdData end

# All have field: result::Dict, data::AbstractSubject
#abstract type AbstractSubjectResult{AbstractSubject} <: AbstractResultData end
abstract type AbstractSubjectResult{AbstractSubject} <: AbstractIDResult{AbstractSubject} end


# Descriptive
