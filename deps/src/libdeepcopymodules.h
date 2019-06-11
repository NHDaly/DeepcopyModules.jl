#include "julia.h"

void setparent(jl_module_t *module, jl_module_t *parent);

jl_value_t* create_function(jl_module_t* modu, jl_sym_t* fname);
