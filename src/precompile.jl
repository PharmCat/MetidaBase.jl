import SnoopPrecompile

SnoopPrecompile.@precompile_all_calls begin
    sdfromcv(0.4)
    varfromcv(0.4)
    cvfromvar(0.4)
    cvfromsd(0.4)
    nonunique([1,2,3,3,4,5,6,6])
    sortbyvec!([1,2,3,4,5,6,7,8], [2,5,3,1,8,4,6,7])
    mt = metida_table([1,2,3], ["a", "b", "c"])
    Tables.istable(mt) 
    Tables.rowaccess(mt) 
    mt = mt[:, [:x1, :x2]]
    mtr = mt[1, :]
    names(mt)
    mt = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    pushfirst!(mt, [0, " "])
    ntr = NamedTuple{(:b, :a)}(["d", 10])
    pushfirst!(mt, ntr)
    size(mt, 1) == 5
    Tables.rows(mt)
    for (i,j) in enumerate(mt)
        mt[i, :a] 
    end
    length(mt)
    mt2 = MetidaBase.metida_table([1,2,3], ["a", "b", "c"], names = (:a, :b))
    append!(mt, mt2)
    mtd = MetidaBase.indsdict!(Dict(), mt)
 
    v1 = [1, 2, -6, missing, NaN, 0]
    itr1 = skipnanormissing(v1)
    for i in itr1
        !isnanormissing(i)
    end
    collect(itr1)
    collect(eachindex(itr1)) 
    eltype(itr1) 
    itr2 = skipnonpositive(v1)
    for i in itr2
        ispositive(i)
    end
    collect(eachindex(itr2))
    eltype(itr2)
    collect(keys(itr2))
    length(itr2)
end