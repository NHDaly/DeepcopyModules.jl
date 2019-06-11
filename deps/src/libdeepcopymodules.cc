
extern "C" {
#include "libdeepcopymodules.h"

void setparent(jl_module_t* module, jl_module_t* parent) {
    module->parent = parent;
}

}
