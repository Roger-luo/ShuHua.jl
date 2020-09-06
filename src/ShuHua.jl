module ShuHua

project(xs...) = normpath(joinpath(dirname(dirname(pathof(ShuHua))), xs...))

include("types.jl")
include("parse.jl")
include("write.jl")
include("build.jl")
include("serve.jl")

using .Types
using .Parse
using .Write

export parse_slide

end
