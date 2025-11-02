# Заполняет словарь d индексами индивидуальных значений

function indsdict!(d::Dict, cdata::Union{Tuple, NamedTuple, AbstractVector{AbstractVector}})
    @inbounds for (i, element) in enumerate(zip(cdata...))
        ind = ht_keyindex(d, element)
        if ind > 0
            push!(d.vals[ind], i)
        else
            v = Vector{Int}(undef, 1)
            v[1] = i
            d[element] = v
        end
    end
    d
end
function indsdict!(d::Dict, cdata::AbstractVector)
    @inbounds for i = 1:length(cdata)
        ind = ht_keyindex(d, cdata[i])
        if ind > 0
            push!(d.vals[ind], i)
        else
            v = Vector{Int}(undef, 1)
            v[1] = i
            d[cdata[i]] = v
        end
    end
    d
end

function indsdict!(d::Dict, mt::MetidaTable)
    indsdict!(d, table(mt))
end

function findfirstvec(x, vec)
    l = length(vec) + 1
    res = findfirst(y -> x == y, vec)
    if isnothing(res) return l else return res end
end
"""
Sort `a` by values of `vec`.
"""
function sortbyvec!(a, vec)
    sort!(a, by = x -> findfirstvec(x, vec))
end

"""
Find all non-unique values.
"""
nonunique(v) = [k for (k, v) in StatsBase.countmap(v) if v > 1]


################################################################################
################################################################################

"""
Return `true` if value NaN or Missing.
"""
isnanormissing(x::Number) = isnan(x)
isnanormissing(x::AbstractFloat) = isnan(x)
isnanormissing(::Missing) = true

"""
Return `true` if value > 0, other cases - `false` (Missing, Nothing, NaN)
"""
ispositive(::Missing) = false
ispositive(::Nothing) = false
ispositive(x::AbstractFloat) = isnan(x) ? false : x > zero(x)
ispositive(x) = x > zero(x)



################################################################################
# Group keyword parsing
################################################################################

parse_gkw(s::String) = [Symbol(s)]
parse_gkw(s::Symbol) = [s]
parse_gkw(s::AbstractVector{<:AbstractString}) = Symbol.(s)
parse_gkw(s::AbstractVector{Symbol}) = s
parse_gkw(s::AbstractVector{Union{AbstractString, Symbol}}) = Symbol.(s)
function parse_gkw(s::AbstractVector)
    if all(x-> isa(x, Union{AbstractString, Symbol}), s)
        return Symbol.(s)
    end
    throw(ArgumentError("Argument should be String, Symbol or AbstractVector{Union{AbstractString, Symbol}}"))
end
parse_gkw(s) = throw(ArgumentError("Argument should be String, Symbol or AbstractVector{Union{AbstractString, Symbol}}"))




################################################################################
################################################################################

# STATISTICS

#CV2se
"""
    sdfromcv(cv)

LnSD from CV.

```math
σ = \\sqrt{log(1 + CV^2)}
```
"""
function sdfromcv(cv)
    return sqrt(varfromcv(cv))
end
"""
    varfromcv(cv)

LnVariance from CV.


```math
σ^2 = log(1 + CV^2)
```

"""
function varfromcv(cv)
     return log(1 + cv^2)
end
"""
    cvfromvar(σ²)

CV from LnVariance.


```math
CV = \\sqrt{exp(σ^2) - 1}
```
"""
function cvfromvar(σ²)
    return sqrt(exp(σ²) - 1)
end
#CV2se
"""
    cvfromsd(σ)

CV from LnSD.


```math
CV = \\sqrt{exp(σ^2) - 1}
```
"""
function cvfromsd(σ)
    return sqrt(exp(σ^2) - 1)
end
