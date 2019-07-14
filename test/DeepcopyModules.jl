using DeepcopyModules

using InteractiveUtils
using Test

module Outer end
@testset "deepcopy_module" begin
    m = @eval Outer module M
        const c = 1
        x = 2
    end

    m2 = DeepcopyModules.deepcopy_module(m)

    @test nameof(m2) == nameof(m)
    @test parentmodule(m2) == parentmodule(m)

    @test names(m2, all=true) == names(m, all=true)
end

@testset "mock module" begin
    m1 = @eval Outer module M1
        x = 1
        f1() = x+1
        f2() = 2
        f3() = f1() + f2()
    end

    m2 = DeepcopyModules.deepcopy_module(m1)

    # Override global variable
    @eval m2 x = $m1.x + 1
    @test m2.x != m1.x
    @test m2.f1() == m1.f1() + 1

    # Override function
    m2.f2() = m1.f1() + 1
    @test m2.f2() == m1.f1() + 1

    # Test overridden references
    @test m2.f3() == m1.f3() + 2  # (+1 for each change)
end

@testset "deepcopy_function" begin
    m1 = @eval module M1 end
    @eval m1 begin
        f() = 2
        foo() = f() + f(); m = methods(foo, ()).ms[1];
    end

    m2 = @eval module M2 end
    DeepcopyModules.deepcopy_function(M2, M1.foo)

    @test M2.foo != M1.foo
    # Successfully pointing at a _new version of f_!
    @test_throws UndefVarError(:f) M2.foo()

    # So copy over f as well
    DeepcopyModules.deepcopy_function(M2, M1.f)
    # And now it works
    @test M2.foo() == 4

    # Redefine f
    M2.f() = 3
    @test M2.foo() == 6

    # And the original is unchanged!
    @test M1.foo() == 4
end

@testset "functions with typevar" begin
    @testset "simple UnionAll" begin
        m1 = @eval module M1
            foo(x::T) where {T} = T
        end
        @assert m1.foo(5) == Int

        m2 = @eval module M2 end
        DeepcopyModules.deepcopy_function(M2, M1.foo)

        @test M2.foo != M1.foo
        @test M2.foo(5) == Int
    end

    @testset "nested UnionAll" begin
        m1 = @eval module M1
            _dims(a::Array{T, N}) where T where N = N
            _eltype(a::Array{T, N}) where T where N = T
        end
        @assert m1._dims([1,2,3]) == 1
        @assert m1._eltype([1,2,3]) == Int

        m2 = @eval module M2 end
        DeepcopyModules.deepcopy_function(m2, m1._dims)
        DeepcopyModules.deepcopy_function(m2, m1._eltype)

        @test m2._dims != m1._dims
        @test m2._eltype != m1._eltype
        @test m2._dims([1,2,3]) == 1
        @test m2._eltype([1,2,3]) == Int
    end
end

@testset "Modules with type definitions" begin
    # TODO: Currently struct definitions are not deep-copied, so this
    # test fails.
    m1 = @eval module M1
        struct S1 x end
    end
    m2 = deepcopy_module(M1)
    @test_broken @eval m2 S1() = S1(1)

    # Make sure that the new method in m2 isn't part of m1
    @test_throws MethodError m1.S1()
end


# ----- Implementation functions: --------

@testset "replace modules" begin
    m2 = @eval module M2 end
    m1 = @eval module M1
        f() = 3
        foo() = f() + f()
    end
    ci = @code_lowered(m1.foo())
    ci2 = DeepcopyModules.code_replace_module(ci, m1=>m2)
    @test ci2 != ci
    @test ci2.code[1].args[1].mod == m2
end

@testset "setparent!" begin
    m = @eval module M end
    @assert parentmodule(m) == Main

    DeepcopyModules.setparent!(m, m)
    @test parentmodule(m) == m

    DeepcopyModules.setparent!(m, Base)
    @test parentmodule(m) == Base

    @testset "create false submodule" begin
        m2 = @eval module M2 end
        DeepcopyModules.setparent!(m2, m)

        @test parentmodule(m2) == m
    end
end

