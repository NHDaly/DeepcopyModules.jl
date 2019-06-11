
extern "C" {
#include "libdeepcopymodules.h"

void setparent(jl_module_t* module, jl_module_t* parent) {
    module->parent = parent;
}

jl_value_t* create_function(jl_module_t* modu, jl_sym_t* fname)
{
    assert(jl_is_symbol(fname));

    jl_value_t *bp_owner = (jl_value_t*)modu;
    jl_binding_t *b = jl_get_binding_for_method_def(modu, fname);
    jl_value_t **bp = &b->value;
    jl_value_t *gf = jl_generic_function_def(b->name, b->owner, bp, bp_owner, b);
    return gf;
}

//jl_value_t* deepcopy_method(jl_module_t* destmodule, jl_module_t* srcmodule, jl_sym_t* fname, jl_value_t)
//{
//    jl_value_t* gf = create_function(destmodule, fname);
//
//    jl_value_t *atypes = NULL, *meth = NULL;
//    JL_GC_PUSH2(&atypes, &meth);
//    atypes = eval_value(args[1], s);
//    meth = eval_value(args[2], s);
//    jl_method_def((jl_svec_t*)atypes, (jl_code_info_t*)meth, s->module);
//    JL_GC_POP();
//    return jl_nothing;
//}

}
