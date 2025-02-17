for N in [Float64, Rational{Int}, Float32]

    # ==================================
    # Constructor and interface methods
    # ==================================

    B = BallInf(zeros(N, 3), N(1))
    v = N[1, 0, 0] # translation along dimension 1
    M = Diagonal(N[1, 2, 3])
    am = AffineMap(M, B, v)

    # dimension check
    @test dim(am) == 3

    # dimension assertion
    @test_throws AssertionError AffineMap(M, B, N[0, 0])
    @test_throws AssertionError AffineMap(M, B × B, v)

    # linear map of an affine map is automatically simplified to an affine map
    Mam = M * am
    @test Mam isa AffineMap && Mam.M == M * am.M && Mam.v == M * am.v

    # scaling of an affine map is an affine map
    α = N(2)
    αam = α * am
    @test αam isa AffineMap && αam.M == α * am.M && αam.v == α * am.v

    # support vector
    sv = σ(N[1, 0, 0], am)
    @test sv[1] == N(2) &&
          sv[2:3] ∈ linear_map(Diagonal(N[2, 3]), BallInf(zeros(N, 2), N(1)))

    # support function
    @test ρ(N[1, 0, 0], am) == N(2)

    # boundedness
    @test isbounded(am) && isboundedtype(typeof(am))
    am2 = AffineMap(M, Universe{N}(3), v)
    @test !isbounded(am2) && !isboundedtype(typeof(am2))

    # is_polyhedral
    @test is_polyhedral(am)
    if N isa AbstractFloat
        am3 = AffineMap(M, Ball2(zeros(N, 3), N(1)), v)
        @test !is_polyhedral(am3)
    end

    # function to get an element
    @test (an_element(am) - am.v) ∈ (am.M * am.X)
    @test an_element(am) ∈ am.M * am.X ⊕ am.v

    # emptiness check
    @test !isempty(am)
    @test isempty(AffineMap(M, EmptySet{N}(2), v))

    # ==================================
    # Type-specific methods
    # ==================================

    # an affine map of the form I*X + b where I is the identity matrix is a pure translation
    #v = N[1, 0, 2]
    #am_tr = AffineMap(I, B, v) # crashes, see #1544
    #@test am_tr isa Translation && am_tr.v == v

    # two-dimensional case
    B2 = BallInf(zeros(N, 2), N(1))
    M = N[1 0; 0 2]
    v = N[-1, 0]
    am = AffineMap(M, B2, v)

    # list of vertices check
    vlist = vertices_list(am)
    @test ispermutation(vlist, [N[0, 2], N[-2, 2], N[0, -2], N[-2, -2]])

    # inclusion check
    h = Hyperrectangle(N[-1, 0], N[1, 2])
    @test h ⊆ am && am ⊆ h

    # concretize
    @test concretize(am) == affine_map(M, B2, v)
end

# tests that only work with Float64 and Float32
for N in [Float64, Float32]
    B = BallInf(zeros(N, 3), N(1))

    # the translation is the origin and the linear map is the identity => constraints remain unchanged
    Id3 = Matrix(one(N) * I, 3, 3)
    @test ispermutation(constraints_list(AffineMap(Id3, B, zeros(N, 3))),
                        constraints_list(B))
end
