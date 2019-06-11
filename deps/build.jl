
outdir = joinpath(@__DIR__, "usr")
mkpath(outdir)

jl_incl = joinpath(dirname(dirname(Base.julia_cmd().exec[1])), "include", "julia")
@show jl_incl

file = joinpath(@__DIR__, "src/libdeepcopymodules.cc")
libflags = `--shared  -undefined dynamic_lookup`

out = "$(@__DIR__)/usr/libdeepcopymodules.dylib"
run(`clang++ -std=c++17 -I $jl_incl $file  $libflags -o $out`)
