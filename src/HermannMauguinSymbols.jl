module HermannMauguinSymbols

# Once we get to 4D and higher space group, this will be updated
const MAXIMUM_DEFINED_DIMENSION = 3

# Valid glide operations (includes reflection m)
# '\x00' represents no glide operation or reflection
const GLIDES = ('\x00', 'a':'e'..., 'g', 'm', 'n')

# Valid centering types in 3D
const CENTERINGS = 
(
    ('p'),
    ('c','p'),
    ('\x00', 'A':'C'..., 'F', 'H', 'I', 'P', 'R'),
)

# Offset between subscripts and regular numbers
const SUBSCRIPT_OFFSET = 0x2050

# Load in all the space group symbols
const SPACE_GROUP_SYMBOLS =
    Tuple(Tuple([ln[2] for ln in split.(readlines("data/sgdata-$(n)d"), 
    '\t', keepempty=false)[2:end]]) for n = 1:MAXIMUM_DEFINED_DIMENSION)

# Operations used when processing strings
include("stringops.jl")
# Defines the data type for axes in a Hermann-Mauguin symbol
include("axis.jl")
# Defines the data type for Hermann-Mauguin symbols of arbitrary dimension
include("hermann-mauguin.jl")

end