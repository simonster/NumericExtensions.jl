# Unit testing for mathfuns.jl

using NumericExtensions
using Base.Test

@test sqr([1, 2, 3]) == [1, 4, 9]
@test_approx_eq rcp([1, 2, 3]) 1.0 / [1, 2, 3]
@test_approx_eq rsqrt([1, 2, 3]) 1.0 / sqrt([1, 2, 3])
@test_approx_eq rcbrt([1, 2, 3]) 1.0 / cbrt([1, 2, 3])

@test NumericExtensions.is_unary_ewise(:-)
@test NumericExtensions.is_unary_ewise(:exp)
@test NumericExtensions.is_binary_ewise(:+)
@test NumericExtensions.is_binary_ewise(:atan2)

@test NumericExtensions.is_binary_sewise(:*)
@test NumericExtensions.is_binary_sewise(:/)
@test NumericExtensions.is_binary_sewise(:\)
@test NumericExtensions.is_binary_sewise(:^)
@test NumericExtensions.is_binary_sewise(:%)

@test !NumericExtensions.is_binary_ewise(:*)
@test !NumericExtensions.is_binary_ewise(:/)
@test !NumericExtensions.is_binary_ewise(:\)
@test !NumericExtensions.is_binary_ewise(:^)
@test !NumericExtensions.is_binary_ewise(:%)

