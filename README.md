# DeepcopyModules

A library that provides a function to deepcopy julia `Module`s, including
deep-copying all their contained functions and variables.

## Motivation

The goal of this package was to support arbitrary non-intrusive mock-testing,
but one can imagine some other uses for this including debugging and
interpreting.

See the original proposal here:
https://discourse.julialang.org/t/deepcopy-module-and-mocking-for-tests/24214

# Usage

```julia
module m1 ... end
m2 = DeepcopyModules.deepcopy_module(m1)
@eval m2 begin ... end  # Do anything you want to modify m2, and m1 is unchanged
```

## Examples

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

