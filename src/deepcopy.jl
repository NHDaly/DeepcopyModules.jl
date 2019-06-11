function deepcopy_module(m::Module)
    m2 = Module(nameof(m), true)
    import_names_into(m2, m)
    setparent!(m2, parentmodule(m))
    return m2
end

usings(m::Module) =
    ccall(:jl_module_usings, Array{Module,1}, (Any,), m)

function import_names_into(destmodule, srcmodule)
    fullsrcname = Meta.parse(join(fullname(srcmodule), "."))
    for m in usings(srcmodule)
        full_using_name = Expr(:., fullname(m)...)
        Core.eval(destmodule, Expr(:using, full_using_name))
    end
    for n in names(srcmodule, all=true, imported=true)
        # don't copy itself into itself; don't copy `include`, define it below instead
        if n != nameof(destmodule) && n != :include
            srcval = Core.eval(srcmodule, n)
            deepcopy_value(destmodule, srcmodule, n, srcval)
        end
    end
    @eval destmodule include(fname::AbstractString) = Main.Base.include(@__MODULE__, fname)
end


# Make new names w/ a copy of the value. For functions, make a new function object.
deepcopy_value(destmodule, srcmodule, name, value) = Core.eval(destmodule, :($name = $(deepcopy(value))))

function deepcopy_value(destmodule, srcmodule, name, value::Function)
    deepcopy_function(destmodule, value)
end
