"""
    HermannMauguin{N}

A Hermann-Mauguin symbol of dimension N. Currently supported from 1 to 3 dimensions.
"""
struct HermannMauguin{N}
    # Centering type of space group
    # Set to '\x00' if it's a point group
    centering::Char
    # Axes of the HM symbol
    axes::NTuple{N,Axis}
    function HermannMauguin{N}(ctr::AbstractChar, ax::NTuple{N,Axis}) where N
        ctr != '\x00' && @assert all(x -> x in (1, 2, 3, 4, 6), order.(ax)) "Order of rotations" *
            "must be 1, 2, 3, 4, or 6 in space groups."
        ctr = uppercase(ctr)
        @assert ctr in CENTERINGS[N] "Invalid centering type: $ctr"
        return new{N}(ctr, ax)
    end
    HermannMauguin{N}(ax::NTuple{N,Axis}) where N = new{N}('\x00', ax)
end

"""
    HermannMauguin(ctr::AbstractChar, ax::Axis...)

Constructs a `HermannMauguin{N}` where N is the number of `Axis` arguments given.
"""
function HermannMauguin(ctr::AbstractChar, ax::Axis...)
    N = length(ax)
    return HermannMauguin{N}(ctr, ax)
end

"""
    HermannMauguin{N}(str::AbstractString) -> HermannMauguin{N}

Constructs a `HermannMauguin{N}` from a string containing a long Hermann-Mauguin symbol.
"""
function HermannMauguin{N}(str::AbstractString) where N
    parts = split(str)
    ctr = '\x00'
    # Try getting the centering if possible
    if parts[1][1] == 'm'
        # Hopefully this fixes issues with HM3"m" and HM3"m m 2"
    elseif isletter(parts[1][1]) && lastindex(parts[1]) == 1
        ctr = only(parts[1])
        parts = parts[2:end]
    end
    ax = Axis.(vcat(parts, ["1" for n = 1:(N - length(parts))]))
    return HermannMauguin{N}(ctr, Tuple(ax))
end

function HermannMauguin{2}(str::AbstractString)
    
end

"""
    HermannMauguin{N}(sg::Int)

Returns the Hermann-Mauguin symbol for the space group of dimension N given its number.
"""
HermannMauguin{N}(sg::Integer) where N = HermannMauguin{N}(SPACE_GROUP_SYMBOLS[N][sg])

"""
    axis_orders(hm::HermannMauguin{N}) -> NTuple{N, Int}

Gets the orders of each rotation axis in a Hermann-Mauguin symbol.

# Examples
```jldoctest
julia> axis_orders(HermannMauguin{3}("F 4_1/d -3 2/m"))
(4, 3, 2)

```
"""
axis_orders(hm::HermannMauguin{N}) where N = order.(hm.axes)

"""
    _string_long(hm::HermannMauguin{3}) -> String

Generates the long form of a 3D Hermann-Mauguin symbol as a `String`.
"""
function _string_long(hm::HermannMauguin{3})
    axis_strings = string.(hm.axes)
    # Strip extraneous rotations if not monoclinic or trigonal
    if hm.centering != 'P' && axis_orders(hm) in ((3,1,2), (3,2,1))
        axis_strings = filter(!isequal("1"), axis_strings)
    end
    # Special handling for low symmetry groups (order 1 rotations only)
    if -1 in getproperty.(hm.axes, :rotation)
        return _centering_prefix(hm) * "-1"
    elseif getproperty.(hm.axes, :rotation) == (1, 1, 1)
        return _centering_prefix(hm) * "1"
    end
    return _centering_prefix(hm) * join(axis_strings, ' ')
end

"""
    _string_short(hm::HermannMauguin{3}) -> String

Generates the short form of a 3D Hermann-Mauguin symbol as a `String`.
"""
function _string_short(hm::HermannMauguin{3})
    # Treat low-symmetry groups specially
    all(isequal(Axis(1)), hm.axes) && return hm.centering * "1"
    Axis(-1) in hm.axes && return hm.centering * "-1"
    ord = axis_orders(hm)
    # Check axis orders for special cases
    if hm.centering == 'P' && ord in ((3, 2, 1), (3, 1, 2))
        # Primitive trigonal space groups with point groups 32, 3m, and -3 2/m
        axis_strings = string.([hm.axes...])
    else
        # Get rid of extraneous onefold operations
        axis_strings = string.(filter(!isequal(Axis(1)), [hm.axes...]))
    end
    # Convert the axis strings to their short forms (remove rotaions/screws)
    if length(axis_strings) > 1
        axes = join([isletter(last(s)) ? string(last(s)) : s for s in axis_strings])
        # If the group isn't high symmetry but has a high order even rotation axis,
        # append the slash notation for the rotation if it's not there already
        if isletter(axes[1]) && ord[1] > 2 && iseven(ord[1]) && ord[2] !=3
            axes = string(hm.axes[1].rotation) *
                   _subscript_string(hm.axes[1].screw)^(!iszero(hm.axes[1].screw)) *
                   '/' * axes
        end
    else
        axes = join(axis_strings)
    end
    return (hm.centering)^(hm.centering != 0) * axes
end

Base.string(hm::HermannMauguin{N}) where N = _string_long(hm)

function Base.display(hm::HermannMauguin{3})
    tp = "point"^ispointgroup(hm) * "space"^isspacegroup(hm)
    disp = 
    [
        "Hermann-Mauguin symbol for a 3-dimensional $tp group:",
        "Long form:\t"  * _string_long(hm),
        "Short form:\t" * _string_short(hm)
    ]
    for ln in disp
        println(ln)
    end
end

function Base.show(io::IO, hm::HermannMauguin{N}) where N
    print(io, "HermannMauguin{$N}(\"$(string(hm))\")")
end

"""
    standardize(hm::HermannMauguin{3})

Converts a 3D Hermann-Mauguin symbol to its standard form as described in the IUCr.

For triclinic cells, this fixes the centering to primitive.

For monoclinic cells, this fixes the centering to either primitive or C-centering, and the b-axis
is the unique axis (with β ≠ 90°).

For orthorhombic cells with point group mm2, this defines the twofold rotation or screw axis to be
the z-axis. 

For tetragonal cells, F-centered and C-centered cells are transformed to I-centered and primitive
cells, respectively.

For trigonal cells, H-centered cells are converted to P-centered cells.

For hexagonal and cubic cells, no changes are made.

# Examples
```jldoctest
julia> standardize()
Hermann-Mauguin symbol for a 3-dimensional space group
Long form:  
Short form: 
```
"""
function standardize(hm::HermannMauguin{3})

end

"""
    ispointgroup(hm::HermannMauguin{N})

Tests if a Hermann-Mauguin symbol represents a point group.
"""
ispointgroup(hm::HermannMauguin) = (hm.centering == '\x00')

"""
    isspacegroup(hm::HermannMauguin{N})

Tests if a Hermann-Mauguin symbol represents a space group.
"""
isspacegroup(hm::HermannMauguin) = (hm.centering != '\x00')

_centering_prefix(hm::HermannMauguin) = (hm.centering * ' ')^(hm.centering != '\x00')

"""
    HM2_str(s::AbstractString) -> HermannMauguin{2}

Generates a 2-dimensional Hermann-Mauguin symbol from a string literal.
"""
macro HM2_str(s::AbstractString)
    HermannMauguin{2}(s)
end

"""
    HM3_str(s::AbstractString) -> HermannMauguin{3}

Generates a 3-dimensional Hermann-Mauguin symbol from a string literal.
"""
macro HM3_str(s::AbstractString)
    HermannMauguin{3}(s)
end