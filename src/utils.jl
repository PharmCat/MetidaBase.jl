
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
