# This script takes header files as input, and generates julia source files from them.
# To use this script, change the filenames below as desired, and then run this script
# via `julia clang-wrap-headers.jl`
#
# This script is modified from the documentation for Clang.jl, here:
# https://github.com/JuliaInterop/Clang.jl

module RunClangWrap

using Clang

# EDIT THIS: Paths that would be included via `-I` in order to compile the specified header.
const INCLUDE = ["/Users/nathan.daly/src/julia_release_native/usr/include/julia"]
# EDIT THIS: The header files to wrap into a julia API.
const HEADERS = ["/Users/nathan.daly/.julia/dev/DeepcopyModules/deps/src/libdeepcopymodules.h"]
# EDIT THIS: Where to store the generated files
const gen_out_dir = "/Users/nathan.daly/.julia/dev/DeepcopyModules/src/gen"
# EDIT THIS: The name of the generated julia API files
const gen_api_name = "libdeepcopymodules"

mkpath(gen_out_dir)
wc = init(; headers = HEADERS,
            output_file = joinpath(gen_out_dir, "$(gen_api_name)_api.jl"),
            common_file = joinpath(gen_out_dir, "$(gen_api_name)_common.jl"),
            clang_includes = vcat(INCLUDE),
            clang_args = vcat((["-I", i] for i in INCLUDE)...),
            header_wrapped = (root, current)->root == current,
            header_library = x->gen_api_name,
            clang_diagnostics = true,
            )

run(wc)

end
