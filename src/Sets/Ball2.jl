import Base: rand,
             ∈

export Ball2,
       sample,
       volume

"""
    Ball2{N<:AbstractFloat, VN<:AbstractVector{N}} <: AbstractBallp{N}

Type that represents a ball in the 2-norm.

### Fields

- `center` -- center of the ball as a real vector
- `radius` -- radius of the ball as a real scalar (``≥ 0``)

### Notes

Mathematically, a ball in the 2-norm is defined as the set

```math
\\mathcal{B}_2^n(c, r) = \\{ x ∈ \\mathbb{R}^n : ‖ x - c ‖_2 ≤ r \\},
```
where ``c ∈ \\mathbb{R}^n`` is its center and ``r ∈ \\mathbb{R}_+`` its radius.
Here ``‖ ⋅ ‖_2`` denotes the Euclidean norm (also known as 2-norm), defined as
``‖ x ‖_2 = \\left( \\sum\\limits_{i=1}^n |x_i|^2 \\right)^{1/2}`` for any
``x ∈ \\mathbb{R}^n``.

### Examples

Create a five-dimensional ball `B` in the 2-norm centered at the origin with
radius 0.5:

```jldoctest ball2_label
julia> B = Ball2(zeros(5), 0.5)
Ball2{Float64, Vector{Float64}}([0.0, 0.0, 0.0, 0.0, 0.0], 0.5)

julia> dim(B)
5
```

Evaluate `B`'s support vector in the direction ``[1,2,3,4,5]``:

```jldoctest ball2_label
julia> σ([1.0, 2, 3, 4, 5], B)
5-element Vector{Float64}:
 0.06741998624632421
 0.13483997249264842
 0.20225995873897262
 0.26967994498529685
 0.3370999312316211
```
"""
struct Ball2{N<:AbstractFloat,VN<:AbstractVector{N}} <: AbstractBallp{N}
    center::VN
    radius::N

    # default constructor with domain constraint for radius
    function Ball2(center::VN, radius::N) where {N<:AbstractFloat,VN<:AbstractVector{N}}
        @assert radius >= zero(N) "the radius must not be negative"
        return new{N,VN}(center, radius)
    end
end

function ○(c::VN, r::N) where {N<:AbstractFloat,VN<:AbstractVector{N}}
    return Ball2(c, r)
end

isoperationtype(::Type{<:Ball2}) = false

"""
    center(B::Ball2)

Return the center of a ball in the 2-norm.

### Input

- `B` -- ball in the 2-norm

### Output

The center of the ball in the 2-norm.
"""
function center(B::Ball2)
    return B.center
end

"""
    radius_ball(B::Ball2)

Return the ball radius of a ball in the 2-norm.

### Input

- `B` -- ball in the 2-norm

### Output

The ball radius.
"""
function radius_ball(B::Ball2)
    return B.radius
end

"""
    ball_norm(B::Ball2)

Return the characteristic norm of a ball in the 2-norm.

### Input

- `B` -- ball in the 2-norm

### Output

The characteristic norm, which is `2`.
"""
function ball_norm(B::Ball2)
    N = eltype(B)
    return N(2)
end

"""
    ρ(d::AbstractVector, B::Ball2)

Return the support function of a 2-norm ball in the given direction.

### Input

- `d` -- direction
- `B` -- ball in the 2-norm

### Output

The support function in the given direction.

### Algorithm

Let ``c`` and ``r`` be the center and radius of the ball ``B`` in the 2-norm,
respectively. Then:

```math
ρ(d, B) = ⟨d, c⟩ + r ‖d‖_2.
```
"""
function ρ(d::AbstractVector, B::Ball2)
    return dot(d, B.center) + B.radius * norm(d, 2)
end

"""
    σ(d::AbstractVector, B::Ball2)

Return the support vector of a 2-norm ball in the given direction.

### Input

- `d` -- direction
- `B` -- ball in the 2-norm

### Output

The support vector in the given direction.
If the direction has norm zero, the center is returned.

### Notes

Let ``c`` and ``r`` be the center and radius of a ball ``B`` in the 2-norm,
respectively.
For nonzero direction ``d`` we have

```math
σ(d, B) = c + r \\frac{d}{‖d‖_2}.
```

This function requires computing the 2-norm of the input direction, which is
performed in the given precision of the numeric datatype of both the direction
and the set.
Exact inputs are not supported.
"""
function σ(d::AbstractVector, B::Ball2)
    dnorm = norm(d, 2)
    if isapproxzero(dnorm)
        return B.center
    else
        return @. B.center + d * (B.radius / dnorm)
    end
end

"""
    ∈(x::AbstractVector, B::Ball2)

Check whether a given point is contained in a ball in the 2-norm.

### Input

- `x` -- point/vector
- `B` -- ball in the 2-norm

### Output

`true` iff ``x ∈ B``.

### Notes

This implementation is worst-case optimized, i.e., it is optimistic and first
computes (see below) the whole sum before comparing to the radius.
In applications where the point is typically far away from the ball, a fail-fast
implementation with interleaved comparisons could be more efficient.

### Algorithm

Let ``B`` be an ``n``-dimensional ball in the 2-norm with radius ``r`` and let
``c_i`` and ``x_i`` be the ball's center and the vector ``x`` in dimension
``i``, respectively.
Then ``x ∈ B`` iff ``\\left( ∑_{i=1}^n |c_i - x_i|^2 \\right)^{1/2} ≤ r``.

### Examples

```jldoctest
julia> B = Ball2([1., 1.], sqrt(0.5))
Ball2{Float64, Vector{Float64}}([1.0, 1.0], 0.7071067811865476)

julia> [.5, 1.6] ∈ B
false

julia> [.5, 1.5] ∈ B
true
```
"""
function ∈(x::AbstractVector, B::Ball2)
    @assert length(x) == dim(B)
    N = promote_type(eltype(x), eltype(B))
    sum = zero(N)
    @inbounds for i in eachindex(x)
        sum += (B.center[i] - x[i])^2
    end
    return _leq(sqrt(sum), B.radius)
end

"""
    rand(::Type{Ball2}; [N]::Type{<:Real}=Float64, [dim]::Int=2,
         [rng]::AbstractRNG=GLOBAL_RNG, [seed]::Union{Int, Nothing}=nothing)

Create a random ball in the 2-norm.

### Input

- `Ball2` -- type for dispatch
- `N`     -- (optional, default: `Float64`) numeric type
- `dim`   -- (optional, default: 2) dimension
- `rng`   -- (optional, default: `GLOBAL_RNG`) random number generator
- `seed`  -- (optional, default: `nothing`) seed for reseeding

### Output

A random ball in the 2-norm.

### Algorithm

All numbers are normally distributed with mean 0 and standard deviation 1.
Additionally, the radius is nonnegative.
"""
function rand(::Type{Ball2};
              N::Type{<:Real}=Float64,
              dim::Int=2,
              rng::AbstractRNG=GLOBAL_RNG,
              seed::Union{Int,Nothing}=nothing)
    rng = reseed!(rng, seed)
    center = randn(rng, N, dim)
    radius = abs(randn(rng, N))
    return Ball2(center, radius)
end

"""
    translate(B::Ball2, v::AbstractVector)

Translate (i.e., shift) a ball in the 2-norm by the given vector.

### Input

- `B` -- ball in the 2-norm
- `v` -- translation vector

### Output

A translated ball in the 2-norm.

### Notes

See also [`translate!(::Ball2, ::AbstractVector)`](@ref) for the in-place
version.
"""
function translate(B::Ball2, v::AbstractVector)
    return translate!(copy(B), v)
end

"""
    translate!(B::Ball2, v::AbstractVector)

Translate (i.e., shift) a ball in the 2-norm by the given vector, in-place.

### Input

- `B` -- ball in the 2-norm
- `v` -- translation vector

### Output

The ball `B` translated by `v`.

### Algorithm

We add the vector to the center of the ball.

### Notes

See also [`translate(::Ball2, ::AbstractVector)`](@ref) for the out-of-place version.
"""
function translate!(B::Ball2, v::AbstractVector)
    @assert length(v) == dim(B) "cannot translate a $(dim(B))-dimensional " *
                                "set by a $(length(v))-dimensional vector"
    c = B.center
    c .+= v
    return B
end

"""
    sample(B::Ball2{N}, [nsamples]::Int;
           [rng]::AbstractRNG=GLOBAL_RNG,
           [seed]::Union{Int, Nothing}=nothing) where {N}

Return samples from a uniform distribution on the given ball in the 2-norm.

### Input

- `B`        -- ball in the 2-norm
- `nsamples` -- number of random samples
- `rng`      -- (optional, default: `GLOBAL_RNG`) random number generator
- `seed`     -- (optional, default: `nothing`) seed for reseeding

### Output

A linear array of `nsamples` elements drawn from a uniform distribution in `B`.

### Algorithm

Random sampling with uniform distribution in `B` is computed using Muller's method
of normalized Gaussians. This function requires the package `Distributions`.
See `_sample_unit_nball_muller!` for implementation details.
"""
function sample(B::Ball2{N}, nsamples::Int;
                rng::AbstractRNG=GLOBAL_RNG,
                seed::Union{Int,Nothing}=nothing) where {N}
    require(@__MODULE__, :Distributions; fun_name="sample")
    n = dim(B)
    D = Vector{Vector{N}}(undef, nsamples) # preallocate output
    _sample_unit_nball_muller!(D, n, nsamples; rng=rng, seed=seed)

    # customize for the given ball
    r, c = B.radius, B.center
    @inbounds for i in 1:nsamples
        axpby!(one(N), c, r, D[i])
    end
    return D
end

# --- Ball2 functions ---

"""
    chebyshev_center_radius(B::Ball2; [kwargs]...)

Compute the [Chebyshev center](https://en.wikipedia.org/wiki/Chebyshev_center)
and the corresponding radius of a ball in the 2-norm.

### Input

- `B`      -- ball in the 2-norm
- `kwargs` -- further keyword arguments (ignored)

### Output

The pair `(c, r)` where `c` is the Chebyshev center of `B` and `r` is the radius
of the largest ball with center `c` enclosed by `B`.

### Notes

The Chebyshev center of a ball in the 2-norm is just the center of the ball.
"""
function chebyshev_center_radius(B::Ball2; kwargs...)
    return B.center, B.radius
end

"""
    volume(B::Ball2)

Return the volume of a ball in the 2-norm.

### Input

- `B` -- ball in the 2-norm

### Output

The volume of ``B``.

### Algorithm

This function implements the well-known formula for the volume of an n-dimensional
ball using factorials. For details see the Wikipedia article
[Volume of an n-ball](https://en.wikipedia.org/wiki/Volume_of_an_n-ball).
"""
function volume(B::Ball2)
    N = eltype(B)
    n = dim(B)
    k = div(n, 2)
    R = B.radius
    if iseven(n)
        vol = N(Base.pi)^k * R^n / factorial(k)
    else
        vol = 2 * factorial(k) * (4 * N(Base.pi))^k * R^n / factorial(n)
    end
    return vol
end

function area(B::Ball2)
    @assert dim(B) == 2 "this function only applies to two-dimensional sets, " *
                        "but the given set is $(dim(B))-dimensional"
    return Base.pi * B.radius^2
end

function project(B::Ball2, block::AbstractVector{Int}; kwargs...)
    return Ball2(B.center[block], B.radius)
end

"""
    reflect(B::Ball2)

Concrete reflection of a ball in the 2-norm `B`, resulting in the reflected set
`-B`.

### Input

- `B` -- ball in the 2-norm

### Output

The `Ball2` representing `-B`.

### Algorithm

If ``B`` has center ``c`` and radius ``r``, then ``-B`` has center ``-c`` and
radius ``r``.
"""
function reflect(B::Ball2)
    return Ball2(-center(B), B.radius)
end

function scale(α::Real, B::Ball2)
    return Ball2(B.center .* α, B.radius * abs(α))
end
