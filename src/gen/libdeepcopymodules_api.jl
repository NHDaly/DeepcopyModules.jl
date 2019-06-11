# Julia wrapper for header: libdeepcopymodules.h
# Automatically generated using Clang.jl


function setparent(_module, parent)
    ccall((:setparent, libdeepcopymodules), Cvoid, (Ptr{jl_module_t}, Ptr{jl_module_t}), _module, parent)
end
