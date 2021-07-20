using MetidaBase
using Test

@testset "MetidaBase.jl" begin
    io       = IOBuffer();
    mt = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    pushfirst!(mt, [0, " "])
    @test mt[1, :a] == 0
    mt[1, :b] = "_"
    @test mt[1, :b] == "_"
    ntr = NamedTuple{(:b, :a)}(["d", 10])
    pushfirst!(mt, ntr)
    @test mt[1, :b] == "d"
    mt[:, :b]
    Base.show(io, mt)

    struct ExampleIDStruct <: MetidaBase.AbstractSubject
        #time
        #obs
        id::Dict
    end

    struct ExampleResultStruct{T} <: MetidaBase.AbstractSubjectResult{T}
        data::T
        result::Dict
    end

    exiddsv = Vector{ExampleIDStruct}(undef, 3)
    for i in 1:3
        exiddsv[i] = ExampleIDStruct(Dict(:a => 1, :b => 1))
    end
    exidds = MetidaBase.DataSet(exiddsv)
    MetidaBase.getid(exidds[2])[:a] = 3
    MetidaBase.getid(exidds[3])[:a] = 2
    MetidaBase.getid(exidds[2])[:b] = 2
    MetidaBase.getid(exidds[3])[:b] = 3
    MetidaBase.getid(exidds, :, :a)

    exrsdsv = Vector{ExampleResultStruct}(undef, length(exidds))

    for i in 1:length(exidds)
        exrsdsv[i] = ExampleResultStruct(exidds[i], Dict(:r1 => 3, :r2 => 4))
    end

    exrsds = MetidaBase.DataSet(exrsdsv)

    @test exrsds[:, :r1][1] == 3
    @test exrsds[1, :r1] == 3

    @test MetidaBase.getid(exidds[3], :a) == 2
    sort!(exidds, :a)
    @test MetidaBase.getid(exidds[3], :a) == 3
    MetidaBase.getid(exrsds, :, :a)

    sort!(exrsds, :a)

    MetidaBase.uniqueidlist(exidds, [:a])
    MetidaBase.uniqueidlist(exidds, :a)

    MetidaBase.subset(exidds, Dict(:a => 1))
    #println(exrsds[:, :r1])

    #println(MetidaBase.getid(exrsds, :, :a1))

end
