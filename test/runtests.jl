using Test
using HermannMauguinSymbols

# Test that long form strings are equivalent to the input
@test string.(HermannMauguin{3}.(1:230)) == [HermannMauguinSymbols.SPACE_GROUP_SYMBOLS[3]...]