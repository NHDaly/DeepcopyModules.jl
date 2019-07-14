"""
    deepcopy_module(m::Module)

Returns a newly constructed Module (`m2`) that is a complete deep-copy of
module `m`, containing deep-copies of all the `name`s in `m`.

All functions contained in `m` are deep-copied, so that the returned module
`m2` contains new generic function objects that have all the same methods as
the functions from `m`, and all code in the new methods will have been modified
so that any references to names in `m` will now be references to names in `m2`.

# Example
```julia-repl
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
"""
function deepcopy_module(m::Module)
    m2 = Module(nameof(m), false)

    @eval m2 include(fname::AbstractString) = Main.Base.include($m2, fname)
    @eval m2 eval(x) = Core.eval($m2, x)

    setparent!(m2, parentmodule(m))
    import_names_into(m2, m)
    return m2
end

usings(m::Module) =
    ccall(:jl_module_usings, Array{Module,1}, (Any,), m)

_full_using_name(modu) = Expr(:., fullname(modu)...)
_import_name_expr(val) = _import_name_expr(parentmodule(val), nameof(val))
_import_name_expr(modu::Module, name::Symbol) = Expr(:(:), _full_using_name(modu), Expr(:., name))

function import_names_into(destmodule, srcmodule)
    for m in usings(srcmodule)
        Core.eval(destmodule, Expr(:using, _full_using_name(m)))
    end
    imports = names(srcmodule, imported=true)
    # don't copy itself into itself; don't copy `include`, defined manually instead
    excluded_names = (nameof(srcmodule), Symbol("#include"), :include)
    imports = setdiff(imports, excluded_names)
    for n in imports
        srcval = Core.eval(srcmodule, n)
        if srcval isa Module
            Core.eval(destmodule, Expr(:import, _full_using_name(srcval)))
        else
            #@show srcmodule, n, typeof(srcval)
            try
                # Try importing from the original source module
                Core.eval(destmodule, Expr(:import, _import_name_expr(srcval)))
            catch
                # Otherwise, import from srcmodule directly
                Core.eval(destmodule, Expr(:import, _import_name_expr(srcmodule, n)))
            end
        end
    end
    ns = setdiff(names(srcmodule, all=true), imports)
    ns = setdiff(ns, excluded_names)
    # Do definitions bottom up to get `Symbol("#foo")` kw defs last
    for n in reverse(ns)
        srcval = Core.eval(srcmodule, n)
        #@show destmodule, srcmodule, n, typeof(srcval)
        # If this name has already been defined by previous steps, skip it
        try Core.eval(destmodule, n) ; continue; catch end
        deepcopy_value(destmodule, srcmodule, n, srcval)
    end
end


# Make new names w/ a copy of the value. For functions, make a new function object.
deepcopy_value(destmodule, srcmodule, name, value) = Core.eval(destmodule, :($name = $(deepcopy(value))))
function deepcopy_value(destmodule, srcmodule, name, value::Function)
    deepcopy_function(destmodule, value)
end
function deepcopy_value(destmodule, srcmodule, name, value::Module)
    m2 = deepcopy_module(value)
    setparent!(m2, destmodule)
    m2
end
# Shallow-copy these as references for now
deepcopy_value(destmodule, srcmodule, name,
               value::Union{Base.Docs.Binding, IdDict}) = Core.eval(destmodule, :($name = $(value)))

# Manually implement "missing" julia Base function to allow setting the parent of a module.
function setparent!(m::Module, p::Module)
    unsafe_store!(Ptr{_Module2}(pointer_from_objref(m)),
                   _Module2(nameof(m), p), 1)
    m
end
# NOTE: This struct must be kept up-to-date with Julia's `_jl_module_t`!
struct _Module2
    name::Symbol
    parent::Module
end
