"""
    _convert_to_subscripts(s::AbstractString)

Converts underscores followed by a number to subscripts.
# Examples
```jldoctest
julia> _convert_to_subscripts("P 4_2/m 2_1/c 2/m")
"P 4₂/m 2₁/c 2/m"

```
"""
function _convert_to_subscripts(s::AbstractString)
    replacements = [a => b for (a, b) = zip('_' .* ('0':'9'), '₀':'₉')]
    for r in replacements
        s = replace(s, r)
    end
    return s
end

"""
    _convert_to_underscores(s::AbstractString)

Converts subscripted numbers to numbers followed by underscores.
# Examples
```jldoctest
julia> _convert_to_underscores("P 4₂/m 2₁/c 2/m")
"P 4_2/m 2_1/c 2/m"

```
"""
function _convert_to_underscores(s::AbstractString)
    replacements = [a => b for (a, b) = zip('₀':'₉', '_' .* ('0':'9'))]
    for r in replacements
        s = replace(s, r)
    end
    return s
end

"""
    _subscript_string(x::Integer) -> String

Converts an `Integer` into a `String` of subscripted digits.
"""
function _subscript_string(x::Integer)
    vc = collect(string(x))
    return join(c .+ SUBSCRIPT_OFFSET for c in vc)
end