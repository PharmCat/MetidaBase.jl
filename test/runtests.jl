using MetidaBase
using Test, Tables, TypedTables, CSV

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

    @test size(mt, 1) == 5
    @test size(mt, 2) == 2

    df = Table(mt)

    rows = Tables.rows(mt)

    for (i,j) in enumerate(mt)
        @test mt[i, :a] == j[1]
        @test mt[i, :b] == j[2]
    end

    l1 = length(mt)
    mt2 = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    append!(mt, mt2)
    @test l1 + length(mt2) == length(mt)
    mt2 = MetidaBase.metida_table(["e", "f", "g"], [1,2,3], names = (:b, :a))
    append!(mt, mt2)

    CSV.write(io, mt)

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

    @test length(MetidaBase.getdata(exidds)) == length(exidds)


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

    @test first(exrsds) == exrsds[1]

    MetidaBase.uniqueidlist(exidds, [:a])
    MetidaBase.uniqueidlist(exidds, :a)

    MetidaBase.subset(exidds, Dict(:a => 1))
    MetidaBase.subset(exrsds, Dict(:a => 1))
    MetidaBase.subset(exrsds, 1:2)

    map(identity, exidds)

    mt = MetidaBase.metida_table(exrsds)
    mt = MetidaBase.metida_table(exrsds; results = :r1, ids = :a)
    Table(exrsds; results = :r1, ids = [:a, :b])
    #Table(exrsds)

    v1 = [1,2,-6,missing,NaN]
    itr1 = MetidaBase.skipnanormissing(v1)
    for i in itr1
        @test !MetidaBase.isnanormissing(i)
    end
    eachindex(itr1)
    eltype(itr1)
    keys(itr1)
    @test length(itr1) == 3

    itr2 = MetidaBase.skipnonpositive(v1)
    for i in itr2
        @test MetidaBase.ispositive(i)
    end
    eachindex(itr2)
    eltype(itr2)
    keys(itr2)
    @test length(itr2) == 2

    MetidaBase.sdfromcv(0.4) ≈ 0.38525317015992666
    MetidaBase.varfromcv(0.4) ≈ 0.1484200051182734
    MetidaBase.cvfromvar(0.4) ≈ 0.7013021443295824
    MetidaBase.cvfromsd(0.4) ≈ 0.41654636115540644

    smt = MetidaBase.Tables.schema(mt)

end
