using MetidaBase
using Test

@testset "MetidaBase.jl" begin
    mt = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    pushfirst!(mt, [0, " "])
    @test mt[1, :a] == 0
    mt[1, :b] = "_"
    @test mt[1, :b] == "_"
    ntr = NamedTuple{(:b, :a)}(["d", 10])
    pushfirst!(mt, ntr)
    @test mt[1, :b] == "d"
end
