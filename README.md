# HermannMauguinSymbols.jl

A library for handling Hermann-Mauguin symbols for point and space groups up to
3 dimensions.

This package is a new project from an inexperienced developer and all
functionality is subject to change.

## Functionality

Hermann-Mauguin symbols are stored in the data type `HermannMauguin{N}` where N
is the number of spatial dimensions.

You can generate a `HermannMauguin{N}` from a string containing the long form
of a Hermann-Mauguin symbol:

```julia
julia> HermannMauguin{3}("F 4_1/d -3 2/m")
Hermann-Mauguin symbol for a 3-dimensional space group
Long form:      F 4₁/d -3 2/m
Short form:     Fd-3m

julia> HermannMauguinSymbols.HermannMauguin{3}("-6 m 2")
Hermann-Mauguin symbol for a 3-dimensional point group
Long form:      -6 m 2
Short form:     -6m2

```

You can also generate a `HermannMauguin{N}` using a space group number:

```julia
julia> HermannMauguin{3}(141)
Hermann-Mauguin symbol for a 3-dimensional space group
Long form:      I 4₁/a 2/m 2/d
Short form:     I4₁/amd

```

A string macro also exists to generate 2-dimensional and 3-dimensional 
Hermann-Mauguin symbols:

```julia
julia> @HM3"P 1 2_1/c 1"
Hermann-Mauguin symbol for a 3-dimensional space group
Long form:      P 1 2₁/c 1
Short form:     P2₁/c

```

# Known issues

Currently, 2-dimensional space group are not handled correctly at all.

Sometimes, Hermann-Mauguin symbols contain extra information about the origin
setting of the unit cell (for instance: F d -3 m Z). This information breaks
the constructor.