# Заполняет словарь d индексами индивидуальных значений
#=
function indsdict!(d::Dict{T, Vector{Int}}, cdata) where T
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
=#
function indsdict!(d::Dict, cdata)
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

"""
Sort `a` by values of `vec`.
"""
function sortbyvec!(a, vec)
    sort!(a, by = x -> findfirst(y -> x == y, vec))
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
isnanormissing(x::Missing) = true

"""
Return `true` if value > 0, other cases - `false` (Missing, Nothing, NaN)
"""
ispositive(::Missing) = false
ispositive(::Nothing) = false
ispositive(x::AbstractFloat) = isnan(x) ? false : x > zero(x)
ispositive(x) = x > zero(x)

################################################################################
################################################################################

# STATISTICS


#CV2se
"""
    sdfromcv(cv::Real)::AbstractFloat

LnSD from CV.
"""
function sdfromcv(cv)
    return sqrt(varfromcv(cv))
end
"""
    varfromcv(cv::Real)::AbstractFloat

LnVariance from CV.
"""
function varfromcv(cv)
     return log(1 + cv^2)
end
"""
    cvfromvar(σ²::Real)::AbstractFloat

CV from variance.
"""
function cvfromvar(σ²)
    return sqrt(exp(σ²) - 1)
end
#CV2se
"""
    cvfromsd(σ::Real)::AbstractFloat

CV from variance.
"""
function cvfromsd(σ)
    return sqrt(exp(σ^2) - 1)
end
