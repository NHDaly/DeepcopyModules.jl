"""
    module Mocking

This module defines the @mock_test macro, which deepcopies a new module in which you can
execute arbitrary setup before running tests. This is useful because it allows you to
redefine behavior without worrying about corrupting the remaining tests.
"""
module Mocking
import DeepcopyModules

export @mock_test

"""
    @mock_test(m::Module, begin ... end, @testset begin ... end)
This macro deepcopies the provided Module, executes the provided setup code in that Module,
and then executes the `test` code in that new module.
This can be used to override behavior of certain parts of your code without worrying about
corrupting behavior in future tests.
# Examples
```julia
@mock_test(
    MyModule,
    begin
        # Override behavior of expensive_code
        struct TestSucceeded end
        expensive_code() = throw(TestSucceeded())
    end,
    @testset "expensive_code is correctly triggered" begin
        @test_throws TestSucceeded MyPackage.parse_args("...")
    end)
)
```
"""
macro mock_test(_module, setup, test)
    quote
        m2 = $DeepcopyModules.deepcopy_module($(esc(_module)))

        @eval m2 eval($(Expr(:quote, setup)))
        @eval m2 eval($(Expr(:quote, test)))
    end
end

end


