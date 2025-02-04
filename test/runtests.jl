using MetidaBase
using Test, Tables, TypedTables, DataFrames, CSV


@testset "MetidaBase.jl" begin

    struct ExampleIDStruct <: MetidaBase.AbstractSubject
        #time
        #obs
        id::Dict
     end
    struct ExampleResultStruct{T} <: MetidaBase.AbstractSubjectResult{T}
        data::T
        result::Dict
    end

    struct ExampleResultData <: MetidaBase.AbstractResultData
        result::Dict
    end

    io       = IOBuffer();
#####################################################################
# metida_table
#####################################################################
    # Metida table names - auto
    mt = MetidaBase.metida_table([1,2,3], ["a", "b", "c"])

    @test  Tables.istable(mt) == true
    @test  Tables.rowaccess(mt) == true

    # Get columns
    mt = mt[:, [:x1, :x2]]
    # Get row
    mtr = mt[1, :]

    @test names(mt) == [:x1, :x2]
    # Metida table names - defined
    mt = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    # Push row
    pushfirst!(mt, [0, " "])
    @test mt[1, :a] == 0
    # Set element
    mt[1, :b] = "_"
    @test mt[1, :b] == "_"
    # push Named tuple as row
    ntr = NamedTuple{(:b, :a)}(["d", 10])
    pushfirst!(mt, ntr)
    @test mt[1, :b] == "d"
    # Test
    @test mt[:, :b] == ["d", "_", "a", "b", "c"]
    # Test show
    @test_nowarn Base.show(io, mt)

    # Tst size
    @test size(mt, 1) == 5
    @test size(mt, 2) == 2

    # Tables rows method
    rows = Tables.rows(mt)

    # MetidaTable > TypedTables
    df = Table(mt)
    df = DataFrame(mt)

    # Enumerate
    for (i,j) in enumerate(mt)
        @test mt[i, :a] == j[1]
        @test mt[i, :b] == j[2]
    end

    # Appent one table to another
    l1 = length(mt)
    mt2 = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    append!(mt, mt2)
    @test l1 + length(mt2) == length(mt)
    mt2 = MetidaBase.metida_table(["e", "f", "g"], [1,2,3], names = (:b, :a))
    append!(mt, mt2)

    # CSV compat test
    @test_nowarn CSV.write(io, mt)

    mtd = MetidaBase.indsdict!(Dict(), mt)
    @test mtd[(3, "c")] == [5, 8]

    mtd = MetidaBase.indsdict!(Dict(), mt[:, 1])
    @test mtd[2] == [4, 7, 10]

############################################################################
# Structures
############################################################################
    
    exiddsv = Vector{ExampleIDStruct}(undef, 3)
    for i in 1:3
        exiddsv[i] = ExampleIDStruct(Dict(:a => 1, :b => 1))
    end
    exidds = MetidaBase.DataSet(exiddsv)
    ############################################################################
    @test Tables.istable(exidds) == false
    @test Tables.rowaccess(exidds) == false
    ############################################################################
    item = ExampleIDStruct(Dict(:c => 6, :j => 6))
    ds1 = deepcopy(exidds)
    ds2 = deepcopy(exidds)
    append!(ds1, ds2)
    @test length(ds1) == 6
    @test MetidaBase.getid(ds1[1])[:a] == MetidaBase.getid(ds1[4])[:a]
    push!(ds1, item)
    @test length(ds1) == 7
    @test MetidaBase.getid(ds1[7]) === item.id

    ############################################################################
    # DATASET Tests
    # Test length
    @test length(MetidaBase.getdata(exidds)) == length(exidds)
    # getid
    MetidaBase.getid(exidds[2])[:a] = 3
    MetidaBase.getid(exidds[3])[:a] = 2
    MetidaBase.getid(exidds[2])[:b] = 2
    MetidaBase.getid(exidds[3])[:b] = 3
    MetidaBase.getid(exidds, :, :a)

    @test MetidaBase.getid_safe(exidds[2], :a) == 3
    @test MetidaBase.getid_safe(exidds[2], :wrongindex) === missing

    @test MetidaBase.getid_unsafe(exidds[2], :a) == 3
    @test_throws KeyError MetidaBase.getid_unsafe(exidds[2], :wrongindex) 


    exrsdsv = Vector{ExampleResultStruct}(undef, length(exidds))
    for i in 1:length(exidds)
        exrsdsv[i] = ExampleResultStruct(exidds[i], Dict(:r1 => 3, :r2 => 4))
    end
    exrsds = MetidaBase.DataSet(exrsdsv)

    # metadata
    dsmeta = MetidaBase.DataSet(exrsdsv, Dict(:name => "SomeName"))

    # Index
    @test exrsds[:, :r1][1] == 3
    @test exrsds[1, :r1] == 3

    @test MetidaBase.getid(exidds[3], :a) == 2

    dsr = exrsds[1:2]
    @test length(dsr) == 2
    @test exrsds[1] === dsr[1]
    @test exrsds[2] === dsr[2]

    @test MetidaBase.getresultindex_safe(exrsds[2], :wrongindex) === missing
    @test MetidaBase.getresultindex_safe(exrsds[2], :r1) == 3
    @test_throws KeyError MetidaBase.getresultindex_unsafe(exrsds[2], :wrongindex) 
    @test MetidaBase.getresultindex_unsafe(exrsds[2], :r1) == 3

    ######################################################################
    # SORT
    ######################################################################
    sort!(exidds, :a)
    @test MetidaBase.getid(exidds[3], :a) == 3
    MetidaBase.getid(exrsds, :, :a)

    @test_nowarn sort!(exrsds, :a)

    @test first(exrsds) == exrsds[1]

    @test_nowarn sort!(exrsds, [:a, :b])

    ########################################################################
    # findfirst
    ########################################################################

    @test MetidaBase.findfirst(exidds, Dict(:a => 1, :b => 1)) == 1
    @test MetidaBase.findlast(exidds, Dict(:a => 1, :b => 1)) == 1
    @test MetidaBase.findall(exidds, Dict(:a => 1, :b => 1)) == [1]  
    @test MetidaBase.findnext(exidds, Dict(:a => 2, :b => 3), 1) == 2
    @test MetidaBase.findprev(exidds, Dict(:a => 2, :b => 3), 3) == 2
    #######################################################################

    ########################################################################
    # find*el
    ########################################################################
    MetidaBase.getid(exidds[2])[:check] = true

    el =  MetidaBase.findfirstel(exidds, Dict(:a => 1, :b => 1)) 
    @test MetidaBase.getid(el)[:a] == 1
    @test MetidaBase.getid(el)[:b] == 1
    el =  MetidaBase.findlastel(exidds, Dict(:a => 1, :b => 1)) 
    @test MetidaBase.getid(el)[:a] == 1 
    @test MetidaBase.getid(el)[:b] == 1
    el =  MetidaBase.findnextel(exidds, Dict(:a => 2, :b => 3), 1) 
    @test MetidaBase.getid(el)[:a] == 2
    @test MetidaBase.getid(el)[:b] == 3
    @test MetidaBase.getid(el)[:check] == true
    el =  MetidaBase.findprevel(exidds, Dict(:a => 2, :b => 3), 3) 
    @test MetidaBase.getid(el)[:a] == 2
    @test MetidaBase.getid(el)[:b] == 3
    @test MetidaBase.getid(el)[:check] == true

    els = MetidaBase.findallel(exidds, Dict(:a => 2, :b => 3))
    @test length(els) == 1
    @test MetidaBase.getid(els[1])[:a] == 2
    @test MetidaBase.getid(els[1])[:b] == 3
    @test MetidaBase.getid(els[1])[:check] == true
    ########################################################################

    MetidaBase.uniqueidlist(exidds, [:a])
    MetidaBase.uniqueidlist(exidds, :a)

    MetidaBase.subset(exidds, Dict(:a => 1))
    MetidaBase.subset(exrsds, Dict(:a => 1))
    MetidaBase.subset(exrsds, 1:2)

    zsbst = MetidaBase.subset(exidds, Dict(:a => 10))
    @test length(MetidaBase.getdata(zsbst)) == 0


    @test_nowarn map(identity, exidds)

    filtexrsds = filter(x -> x.id[:a] == 2, exidds)
    filter!(x -> x.id[:a] == 2, exidds)

    @test length(filtexrsds) == length(exidds)
    @test filtexrsds[1].id[:a] == exidds[1].id[:a] == 2

    ############################################################################
    # Table
    mt  = MetidaBase.metida_table(exrsds)
    mt  = MetidaBase.metida_table(exrsds; results = :r1, ids = :a)
    smt = MetidaBase.Tables.schema(mt)

    ############################################################################

    # TypedTables export
    @test_nowarn Table(exrsds; results = :r1, ids = [:a, :b])

    # DataFrames export
    @test_nowarn DataFrame(exrsds; results = :r1, ids = [:a, :b])

    ############################################################################
    #Iterators data
    v1 = [1, 2, -6, missing, NaN, 0]

    #Iterators tests
    itr1 = MetidaBase.skipnanormissing(v1)
    for i in itr1
        @test !MetidaBase.isnanormissing(i)
    end
    @test collect(itr1) == [1.0, 2.0, -6.0, 0.0]
    @test collect(eachindex(itr1)) == [1, 2, 3, 6]
    @test eltype(itr1) <: Float64
    @test collect(keys(itr1))  == [1, 2, 3, 6]
    @test length(itr1) == 4

    @test getindex(itr1, 1) == 1
    @test_nowarn eltype(itr1)
    @test_throws ErrorException itr1[4]
    @test_throws ErrorException itr1[5]

    itr2 = MetidaBase.skipnonpositive(v1)
    for i in itr2
        @test MetidaBase.ispositive(i)
    end
    @test collect(eachindex(itr2)) == [1, 2]
    eltype(itr2)
    @test collect(keys(itr2))  == [1, 2]
    @test length(itr2) == 2

    @test getindex(itr2, 2) == 2
    @test_nowarn eltype(itr2)
    @test_throws ErrorException itr2[3]
    @test_throws ErrorException itr2[4]
    @test_throws ErrorException itr2[5]
    @test_throws ErrorException itr2[6]
    

############################################################################
 # OTHER
    @test MetidaBase.nonunique([1,2,3,3,4,5,6,6]) == [6,3]

    @test MetidaBase.sortbyvec!([1,2,3,4,5,6,7,8], [2,5,3,1,8,4,6,7]) == [2,5,3,1,8,4,6,7]
    @test MetidaBase.sortbyvec!([1,2,3,4,5,6,7,8], [2,5,3,8,4,6,7])   == [2,5,3,8,4,6,7,1]
############################################################################
# Stat utils
    MetidaBase.sdfromcv(0.4) ≈ 0.38525317015992666
    MetidaBase.varfromcv(0.4) ≈ 0.1484200051182734
    MetidaBase.cvfromvar(0.4) ≈ 0.7013021443295824
    MetidaBase.cvfromsd(0.4) ≈ 0.41654636115540644


    @test  MetidaBase.parse_gkw("s")    == [:s]
    @test  MetidaBase.parse_gkw(:s)     == [:s]
    @test  MetidaBase.parse_gkw([:s])   == [:s]
    @test  MetidaBase.parse_gkw(["s"])  == [:s]

# ExampleResultData


    erd = Vector{ExampleResultData}(undef, 10)
    for i in 1:10
        erd[i] = ExampleResultData(Dict(:p1 => 3, :p2 => :param, :p3 => true))
    end
    erdds = MetidaBase.DataSet(erd)

    @test getindex(erdds[1], :p1) == 3

    @test MetidaBase.getresultindex_safe(erdds[1], :p1) == 3
    @test MetidaBase.getresultindex_safe(erdds[1], :wrongindex) === missing

    @test MetidaBase.getresultindex_unsafe(erdds[1], :p1) == 3
    @test_throws KeyError MetidaBase.getresultindex_unsafe(erdds[1], :wrongindex) 
end
