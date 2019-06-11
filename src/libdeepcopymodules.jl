
# C functions
module GenAPI

const libdeepcopymodules = joinpath(dirname(@__DIR__), "deps/usr/libdeepcopymodules.dylib")

const jl_module_t = Module

include("gen/libdeepcopymodules_api.jl")

end

function setparent!(_module, parent)
    #ccall((:setparent, libdeepcopymodules), Cvoid, (Ptr{Module}, Ptr{Module}), _module, parent)
    GenAPI.setparent(pointer_from_objref(_module), pointer_from_objref(parent))
end
