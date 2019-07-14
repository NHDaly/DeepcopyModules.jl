using AbstractTrees

# Replace module in Expr tree
function expr_replace_module(expr, pat::Pair{Module, Module})
    expr_replace_module!(deepcopy(expr), pat)
end
function expr_replace_module!(expr, pat::Pair{Module, Module})
    treemap!(PreOrderDFS(expr)) do node
        if node isa GlobalRef && node.mod == pat.first
            GlobalRef(pat.second, node.name)
        else
            node
        end
    end
end


# Replace Module in CodeInfo
function code_replace_module(code::Core.CodeInfo, pat::Pair{Module, Module})
    code2 = copy(code)  # I guess this is sufficient...
    code_replace_module!(code2, pat)
end
function code_replace_module!(code::Core.CodeInfo, pat::Pair{Module, Module})
    for e in code.code
        expr_replace_module!(e, pat)
    end
    code
end

# Deepcopy Function

compressed_ast(m::Method, ci::Core.CodeInfo) =
    ccall(:jl_compress_ast, Any, (Any, Any), m, ci)

function deepcopy_function(destmodule::Module, f::Function)
    name = nameof(f)
    f2 = try
            Core.eval(destmodule, name)
        catch
            @eval destmodule function $name end
        end
    src_ms = methods(f).ms
    for m in src_ms
        deepcopy_method(destmodule, m, f2)
    end
end

_func_sig_params(t) = t isa UnionAll ? _func_sig_params(t.body) : t.parameters[2:end]
_func_sig_typeparams(t) = t isa UnionAll ? (t.var, _func_sig_typeparams(t.body)...) : ()
function deepcopy_method(destmodule, m, func::Function)
    # TODO: is it okay to use m.sig.parameters
    argdata = Core.svec(Core.svec(typeof(func), _func_sig_params(m.sig)...),
                        Core.svec(_func_sig_typeparams(m.sig)...))

    ci = Base.uncompressed_ast(m)
    ci = code_replace_module!(ci, m.module => destmodule)

    ccall(:jl_method_def, Cvoid, (Core.SimpleVector, Any, Ptr{Module}), argdata, ci, pointer_from_objref(destmodule))
end
