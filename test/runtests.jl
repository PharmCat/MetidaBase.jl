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



    struct ExampleIDStruct <: MetidaBase.AbstractIdData
        id::Dict
    end

    struct ExampleResultStruct <: MetidaBase.AbstractResultData
        subject::ExampleIDStruct
        result::Dict
    end

    exidds = MetidaBase.DataSet(fill(ExampleIDStruct(Dict(:a => 1, :b => 2)), 3))

    exrsdsv = Vector{ExampleResultStruct}(undef, length(exidds))

    for i in 1:length(exidds)
        exrsdsv[i] = ExampleResultStruct(exidds[i], Dict(:r1 => 3, :r2 => 4))
    end

    exrsds = MetidaBase.DataSet(exrsdsv)

    @test exrsds[:, :r1][1] == 3

    #println(exrsds[:, :r1])

    #println(MetidaBase.getid(exrsds, :, :a1))

end
