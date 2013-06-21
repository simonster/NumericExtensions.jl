# Reduction functions related to statistics

using NumericFunctors
using Base.Test

# mean

macro check_nonempty(funname)
	quote
		if isempty(x)
			error("$($funname) of empty collection undefined")
		end
	end
end

function mean(x::Array)
	@check_nonempty("mean")
	sum(x) / length(x)
end

function mean{T<:Real}(x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	r = to_fparray(sum(x, dims))
	c = convert(eltype(r), inv(_reduc_dim_length(x, dims)))
	multiply!(r, c)
end

function mean!{R<:Real,T<:Real}(dst::Array{R}, x::Array{T}, dims::DimSpec)
	@check_nonempty("mean")
	c = convert(R, inv(_reduc_dim_length(x, dims)))
	multiply!(sum!(dst, x, dims), c)
end

# var

function _var{R<:FloatingPoint, T<:Real}(::Type{R}, x::Array{T}, ifirst::Int, ilast::Int)
	xi = x[ifirst]
	s = convert(R, xi)
	s2 = convert(R, xi * xi)

	for i in ifirst+1 : ilast
		xi = x[i]
		s += xi
		s2 += xi * xi
	end

	nm1 = ilast - ifirst
	n = nm1 + 1
	mu = s / n
	max((s2 - n * (mu * mu)) / nm1, zero(R))
end


function var{T<:Real}(x::Array{T})
	@check_nonempty("var")
	_var(to_fptype(T), x, 1, length(x))
end


function var!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Vector{T}, dim::Int)
	if dim == 1
		dst[1] = var(x)
	else
		error("var: dim must be 1 for vector.")
	end
	dst
end

function _varimpl_firstdim!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Array{T}, m::Int, n::Int)
	o = 0
	for j in 1 : n
		dst[j] = _var(R, x, o+1, o+m)
		o += m
	end
end

function _varimpl_lastdim!{R<:FloatingPoint,T<:Real}(dst::Array{R}, s::Array{R}, x::Array{T}, m::Int, n::Int)
	for i in 1 : m
		xi = x[i]
		s[i] = xi
		dst[i] = xi * xi
	end

	o = m
	for j in 2 : n
		for i in 1 : m
			xi = x[o + i]
			s[i] += xi
			dst[i] += xi * xi
		end
		o += m
	end

	inv_n = one(R) / convert(R, n)
	inv_nm1 = one(R) / convert(R, n - 1)
	for i in 1 : m
		mu = s[i] * inv_n
		dst[i] = max(dst[i] - n * (mu * mu), zero(R)) * inv_nm1
	end
end

function _varimpl_middim!{R<:FloatingPoint,T<:Real}(dst::Array{R}, s::Array{R}, x::Array{T}, m::Int, n::Int, k::Int)
	s = Array(R, n)

	_varimpl_lastdim!(dst, s, x, m, n)

	for l in 2 : k
		_varimpl_lastdim!(view(dst, :, l), s, view(x, :, :, l), m, n)
	end
end


function var!{R<:FloatingPoint,T<:Real}(dst::Array{R}, x::Array{T}, dim::Int)
	@check_nonempty("var")
	nd = ndims(x)
	if !(1 <= dim <= nd)
		error("var: invalid value for the dim argument.")
	end
	siz = size(x)

	if dim == 1
		_varimpl_firstdim!(dst, x, siz[1], trail_length(siz, dim))
	elseif dim == nd
		prelen = precede_length(siz, dim)
		_varimpl_lastdim!(dst, Array(R, prelen), x, prelen, siz[dim])
	else
		prelen = precede_length(siz, dim)
		_varimpl_middim!(dst, Array(R, prelen), x, prelen, siz[dim], trail_length(siz, dim))
	end
	dst
end

function var{T<:Real}(x::Array{T}, dim::Int)
	var!(Array(to_fptype(T), reduced_size(size(x), dim)), x, dim)
end

# std

std{T<:Real}(x::Array{T}) = sqrt(var(x))
std{T<:Real}(x::Array{T}, dim::Int) = sqrt!(var(x, dim))
std!{R<:FloatingPoint, T<:Real}(dst::Array{R}, x::Matrix{T}, dim::Int) = sqrt!(var!(dst, x, dim))

# entropy

entropy(x::Array) = - sum_xlogx(x)
entropy(x::Array, dims::DimSpec) = negate!(sum_xlogx(x, dims))
entropy!(dst::Array, x::Array, dims::DimSpec) = negate!(sum_xlogx!(dst, x, dims))


