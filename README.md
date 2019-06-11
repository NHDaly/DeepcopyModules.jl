# DeepcopyModules

A library that provides a function to deepcopy julia `Module`s, including
deep-copying all their contained functions and variables.

## Motivation

The goal of this package was to support arbitrary non-intrusive mock-testing,
but one can imagine some other uses for this including debugging and
interpreting.

See the original proposal here:
https://discourse.julialang.org/t/deepcopy-module-and-mocking-for-tests/24214

