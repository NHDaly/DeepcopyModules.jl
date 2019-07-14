# DeepcopyModules

> _"You can't really copy what I do because I don't do anything." – David Bailey_


A library that provides a function to deepcopy julia `Module`s, including
deep-copying all their contained functions and variables.

## Motivation

The goal of this package was to support arbitrary non-intrusive mock-testing,
but one can imagine some other uses for this including debugging and
interpreting.

See the original proposal here:
https://discourse.julialang.org/t/deepcopy-module-and-mocking-for-tests/24214

# Usage

    deepcopy_module(m::Module)

Returns a newly constructed Module (`m2`) that is a complete deep-copy of
module `m`, containing deep-copies of all the `name`s in `m`.

All functions contained in `m` are deep-copied, so that the returned module
`m2` contains new generic function objects that have all the same methods as
the functions from `m`, and all code in the new methods will have been modified
so that any references to names in `m` will now be references to names in `m2`.

```julia
julia> module M;  x = 1;  f() = (global x += 1);  end
Main.M

julia> M2 = deepcopy_module(M)
Main.M

julia> M2.f()  # This only modifies the copy of `x` in M2.
2

julia> M2.x, M.x
(2, 1)

julia> nameof(M2)  # Inside M2, it still believes it's module M
:M
```

## Example Usage: Mocking.jl

The file [examples/mocking.jl](examples/mocking.jl) contains an example of
using this package to implement a mock-testing framework:
```julia
macro mock_test(_module, setup, test)
    quote
        m2 = $DeepcopyModules.deepcopy_module($(esc(_module)))
        @eval m2 eval($(Expr(:quote, setup)))
        @eval m2 eval($(Expr(:quote, test)))
    end
end
```

Which can then be used as follows:
```julia
julia> @mock_test(
           AppMain,
           begin
               using Test
               run_app_was_triggerred = fill(false)
               AppMain.run_app() = run_app_was_triggerred[] = true
           end,
           @testset "run_app" begin
               AppMain.main(["run"])
               @test run_app_was_triggerred[]
           end)
Test Summary: | Pass  Total
run_app       |    1      1
Test.DefaultTestSet("run_app", Any[], 1, false)
```

