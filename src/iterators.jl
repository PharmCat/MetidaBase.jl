################################################################################
struct SkipNonPositive{T}
    x::T
end
skipnonpositive(itr) = SkipNonPositive(itr)

Base.IteratorEltype(::Type{SkipNonPositive{T}}) where {T} = Base.IteratorEltype(T)
Base.eltype(::Type{SkipNonPositive{T}}) where {T} = nonmissingtype(eltype(T))
function Base.iterate(itr::SkipNonPositive, state...)
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while !ispositive(item)
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end
Base.IndexStyle(::Type{<:SkipNonPositive{T}}) where {T} = IndexStyle(T)
Base.eachindex(itr::SkipNonPositive) =
    Iterators.filter(i -> ispositive(@inbounds(itr.x[i])), eachindex(itr.x))
Base.keys(itr::SkipNonPositive) =
    Iterators.filter(i -> ispositive(@inbounds(itr.x[i])), keys(itr.x))
Base.@propagate_inbounds function getindex(itr::SkipNonPositive, I...)
    v = itr.x[I...]
    !ispositive(v) && throw(ErrorException("the value at index $I is non positive"))
    v
end
function Base.length(itr::SkipNonPositive)
    n = 0
    for i in itr n+=1 end
    n
end
################################################################################
struct SkipNaNorMissing{T}
    x::T
end
skipnanormissing(itr) = SkipNaNorMissing(itr)

Base.IteratorEltype(::Type{SkipNaNorMissing{T}}) where {T} = Base.IteratorEltype(T)
Base.eltype(::Type{SkipNaNorMissing{T}}) where {T} = nonmissingtype(eltype(T))
function Base.iterate(itr::SkipNaNorMissing, state...)
    y = iterate(itr.x, state...)
    y === nothing && return nothing
    item, state = y
    while isnanormissing(item)
        y = iterate(itr.x, state)
        y === nothing && return nothing
        item, state = y
    end
    item, state
end
Base.IndexStyle(::Type{<:SkipNaNorMissing{T}}) where {T} = IndexStyle(T)
Base.eachindex(itr::SkipNaNorMissing) =
    Iterators.filter(i -> !isnanormissing(@inbounds(itr.x[i])), eachindex(itr.x))
Base.keys(itr::SkipNaNorMissing) =
    Iterators.filter(i -> !isnanormissing(@inbounds(itr.x[i])), keys(itr.x))
Base.@propagate_inbounds function getindex(itr::SkipNaNorMissing, I...)
    v = itr.x[I...]
    isnanormissing(v) && throw(ErrorException("The value at index $I is NaN or missing!"))
    v
end
function Base.length(itr::SkipNaNorMissing)
    n = 0
    for i in itr n+=1 end
    n
end
################################################################################
