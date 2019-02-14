for _dummy_ in 1:1 # avoid global variable warnings
    # reseeding with random seed
    rng = LazySets.GLOBAL_RNG
    seed = rand(1:10000)
    LazySets.reseed(rng, seed)
    n1 = rand(Int)
    LazySets.reseed(rng, seed)
    n2 = rand(Int)
    @test n1 == n2

    # StrictlyIncreasingIndices
    vectors = Vector{AbstractVector{Int}}()
    for v in LazySets.StrictlyIncreasingIndices(5, 4)
        push!(vectors, copy(v))
    end
    @test vectors == [[1, 2, 3, 4], [1, 2, 3, 5], [1, 2, 4, 5], [1, 3, 4, 5], [2, 3, 4, 5]]

    # invertible matrix
    @test LazySets.isinvertible([2 3; 1 2])
    @test !LazySets.isinvertible([2 3; 0 0])

    for N in [Float64, Rational{Int}, Float32]
        # substitution
        x = N[1, 2, 3]
        substitution = Dict(1 => N(4), 3 => N(0))
        @test LazySets.substitute(substitution, x) == N[4, 2, 0]
        LazySets.substitute!(substitution, x)
        @test x == N[4, 2, 0]
    end

    for N in [Float64, Float32]
        # modified dot product
        @test isnan(dot(N[1, 0], N[Inf, -Inf]))
        @test LazySets.dot_zero(N[1, 0], N[Inf, -Inf]) == N(Inf)
    end
end
