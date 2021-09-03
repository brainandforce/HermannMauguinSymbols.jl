"""
    Axis

One of the axes that is described in a long-form Hermann-Mauguin symbol.

For instance, in space group 51 (P 2₁/m 2/m 2/a or Pmma), there are three axes: 2₁/m, 2/m, and 2/a.

Every `Axis` has three different parameters:

`rotation`: the rotation order of the axis. For space groups, must be 1, 2, 3, 4, or 6 (per the 
crystallographic restriction theorem).

`screw`: The order of the screw axis. If 0, the operation is a normal rotation. Must be less than
the order of the rotation operation.

`glide`: The type of glide or reflection operation. Can be a, b, c, d, e, g, m, or n.
"""
struct Axis
    # Order of rotation
    rotation::Int
    # Order of screw axis: 0 indicates pure rotation
    screw::Int
    # Mirror or glide operation
    glide::Char
    function Axis(r::Number, s::Number, g::AbstractChar)
        # Ensure that rotation order is nonzero
        @assert r != 0 "Rotation order cannot be zero"
        # Screw axis order must be between 0 and r - 1
        # Set to 0 if negative
        if r > 0
            s = s % r
        else
            s = 0
        end
        # Reflections/glides must be valid symbols
        g = lowercase(g)
        @assert g in GLIDES "Invalid reflection or glide operation: $g"
        return new(r, s, g)
    end
end

# Pure glides
Axis(g::AbstractChar) = Axis(1, 0, g)
# Pure rotations/rotoinversions
Axis(r::Number) = Axis(r, 0, '\x00')
# Screw axes
Axis(r::Number, s::Number) = Axis(r, s, '\x00')
# Reflections and glides without screw axes
Axis(r::Number, g::AbstractChar) = Axis(r, 0, g)

"""
    Axis(s::AbstractString)

Constructs an `Axis` of a Hermann-Mauguin symbol.

# Examples
```jldoctest
julia> Axis("4_2/m")
Axis("4₂/m")

```
"""
function Axis(str::AbstractString)
    # Empty strings should just be 
    isempty(str) && return Axis(1, 0, '\x00')
    # -2 should be m in all circumstances
    # TODO: this needs to be handled better
    startswith(lstrip(str), "-2") && return Axis(1, 0, 'm')
    # convert to standard subscripts
    str = _convert_to_subscripts(str)
    # Get rotational component
    rotation = filter(c -> isdigit(c) || c in ('-', '–'), str)
    screw = filter(in('₀':'₉'), str)
    glide = filter(isletter, str)
    (r, s, g) = (1, 0, '\x00')
    isempty(rotation) || (r = parse(Int, rotation))
    isempty(screw) || (s = parse(Int, join(c - SUBSCRIPT_OFFSET for c in screw)))
    isempty(glide) || (g = only(glide))
    return Axis(r, s, g)
end

function Base.string(ax::Axis)
    r = string(ax.rotation)
    # Rotoinversions have no screw/glide components; return immediately
    ax.rotation < 0 && return r
    # If a pure reflection/glide, jut return glide component
    ax.rotation == 1 && ax.glide != '\x00' && return string(ax.glide)
    # Convert screw axes to subscripts
    s::String = _subscript_string(ax.screw)^(ax.screw != 0)
    # Add in glide component if needed
    g = ("/" * ax.glide)^(ax.glide != '\x00')
    return r * s * g
end

Base.show(io::IO, ax::Axis) = print(io, "Axis(\"" * string(ax) * "\")")

Base.display(ax::Axis) = println("Hermann-Mauguin axis: " * string(ax))

macro ax_str(s)
    Axis(s)
end

"""
    order(ax::Axis)

Gets the rotation order of an `Axis`. Equivalent to the absolute value of the rotational component,
but will be 2 if the rotational component is of order 1 and there is a glide or reflection.
"""
function order(ax::Axis)
    r = abs(ax.rotation)
    # If there is a glide operation, return 2 at least
    r == 1 && ax.glide != '\x00' && return 2
    return r
end