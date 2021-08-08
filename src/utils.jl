
function indsdict!(d::Dict{T}, cdata::Tuple) where T
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

function sortbyvec!(a, vec)
    sort!(a, by = x -> findfirst(y -> x == y, vec))
end

isnanormissing(x::Number) = isnan(x)
isnanormissing(x::Missing) = true


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
     return log(1+cv^2)
end
"""
    cvfromvar(σ²::Real)::AbstractFloat

CV from variance.
"""
function cvfromvar(σ²)
    return sqrt(exp(σ²)-1)
end
#CV2se
"""
    cvfromsd(σ::Real)::AbstractFloat

CV from variance.
"""
function cvfromsd(σ)
    return sqrt(exp(σ^2)-1)
end
