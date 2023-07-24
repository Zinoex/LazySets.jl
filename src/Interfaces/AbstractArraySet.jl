const AbstractArraySet = Union{CartesianProductArray,
                               ConvexHullArray,
                               IntersectionArray,
                               MinkowskiSumArray,
                               UnionSetArray}

function Base.getindex(X::AbstractArraySet, i)
    return getindex(array(X), i)
end

function Base.length(X::AbstractArraySet)
    return length(array(X))
end

function Base.iterate(X::AbstractArraySet, state=1)
    return iterate(array(X), state)
end

function flatten!(arr, X, bin_op)
    if X isa bin_op
        flatten!(arr, first(X), bin_op)
        flatten!(arr, second(X), bin_op)
    elseif X isa array_constructor(bin_op)
        for Xi in X
            flatten!(arr, Xi, bin_op)
        end
    else
        push!(arr, X)
    end
    return arr
end
