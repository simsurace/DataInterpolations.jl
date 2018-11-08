### Linear Interpolation
struct LinearInterpolation{uType,tType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  LinearInterpolation{FT}(u,t) where FT = new{typeof(u),typeof(t),FT,eltype(u)}(u,t)
end
LinearInterpolation(u,t) = LinearInterpolation{true}(u,t)

### Quadratic Interpolation
struct QuadraticInterpolation{uType,tType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  QuadraticInterpolation{FT}(u,t) where FT = new{typeof(u),typeof(t),FT,eltype(u)}(u,t)
end
QuadraticInterpolation(u,t) = QuadraticInterpolation{true}(u,t)

### Lagrange Interpolation
struct LagrangeInterpolation{uType,tType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  n::Int
  LagrangeInterpolation{FT}(u,t,n) where FT = new{typeof(u),typeof(t),FT,eltype(u)}(u,t,n)
end
LagrangeInterpolation(u,t,n) = LagrangeInterpolation{true}(u,t,n)

### QuadraticSpline Interpolation
struct QuadraticSpline{uType,tType,tAType,dType,zType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  tA::tAType
  d::dType
  z::zType
  QuadraticSpline{FT}(u,t,tA,d,z) where FT = new{typeof(u),typeof(t),typeof(tA),
                                                  typeof(d),typeof(z),FT,eltype(u)}(u,t,tA,d,z)
end

function QuadraticSpline(u,t)
  s = length(t)
  dl = ones(eltype(t),s-1)
  d = ones(eltype(t),s)
  du = zeros(eltype(t),s-1)
  tA = Tridiagonal(dl,d,du)
  d = zero(t)
  for i = 2:length(d)
    d[i] = 2//1 * (u[i] - u[i-1])/(t[i] - t[i-1])
  end
  z = tA\d
  QuadraticSpline{true}(u,t,tA,d,z)
end

# Cubic Spline Interpolation
struct CubicSpline{uType,tType,hType,zType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  h::hType
  z::zType
  CubicSpline{FT}(u,t,h,z) where FT = new{typeof(u),typeof(t),typeof(h),typeof(z),FT,eltype(u)}(u,t,h,z)
end

function CubicSpline(u,t)
  n = length(t) - 1
  h = vcat(0, diff(t), 0)
  dl = h[2:n+1]
  d = 2 .* (h[1:n+1] .+ h[2:n+2])
  du = h[2:n+1]
  tA = LinearAlgebra.Tridiagonal(dl,d,du)
  d = zero(t)
  for i = 2:n
    d[i] = 6(u[i+1] - u[i]) / h[i+1] - 6(u[i] - u[i-1]) / h[i]
  end
  z = tA\d
  CubicSpline{true}(u,t,h[1:n+1],z)
end

### BSpline Interpolation
struct BSpline{uType,tType,pType,kType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  d::Int    # degree
  p::pType  # params vector
  k::kType  # knot vector
  pVec::Symbol
  knotVec::Symbol
  BSpline{FT}(u,t,d,p,k,pVec,knotVec) where FT =  new{typeof(u),typeof(t),typeof(p),typeof(k),FT,eltype(u)}(u,t,d,p,k,pVec,knotVec)
end

function BSpline(u,t,d,pVec,knotVec)
  n = length(t)
  s = zero(eltype(u))
  p = zero(t)
  l = zeros(eltype(u),n-1)

  for i = 2:n
    s += sqrt((t[i] - t[i-1])^2 + (u[i] - u[i-1])^2)
    l[i-1] = s
  end

  a = p[1] = 0; b = p[end] = 1

  if pVec == :Uniform
    for i = 2:(n-1)
      p[i] = a + (i-1)*(b-a)/(n-1)
    end
  elseif pVec == :ArcLen
    for i = 2:(n-1)
      p[i] = a + l[i-1]/s * (b-a)
    end
  end

  ps = zero(t)
  s = zero(eltype(t))
  for i = 1:n
    s += p[i]
    ps[i] = s
  end

  lk = n + d + 1
  k = zeros(eltype(t),lk)
  for i = lk:-1:(n+1)
    k[i] = one(eltype(t))
  end

  if knotVec == :Uniform
    # uniformly spaced knot vector
    for i = (d+2):n
      k[i] = (i-d-1)//(n-d)
    end
  elseif knotVec == :Average
    # average spaced knot vector
    idx = 1
    if d+2 <= n
      k[d+2] = 1//d * ps[d]
    end
    for i = (d+3):n
      k[i] = 1//d * (ps[idx+d] - ps[idx])
      idx += 1
    end
  end
  BSpline{true}(u,t,d,p,k,pVec,knotVec)
end

### Loess
struct Loess{uType,tType,αType,xType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  d::Int
  α::αType
  q::Int
  x::xType
  Loess{FT}(u,t,d,α,q,x) where FT = new{typeof(u),typeof(t),typeof(α),typeof(x),FT,eltype(u)}(u,t,d,α,q,x)
end

function Loess(u,t,d,α)
  n = length(t)
  q = floor(Int,n*α)
  x = Matrix{eltype(t)}(undef,n,d+1)
  x[:,1] .= one(t[1])
  for i = 2:(d+1)
    x[:,i] = t .^ (i-1)
  end
  Loess{true}(u,t,d,α,q,x)
end

### GaussianProcesses
struct GPInterpolation{uType,tType,gpType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  gp::gpType
  GPInterpolation{FT}(u,t,gp) where FT = new{typeof(u),typeof(t),typeof(gp),FT,eltype(u)}(u,t,gp)
end

function GPInterpolation(u,t,m,k,n=-2.0)
  gp = GP(t,u,m,k,n)
  GPInterpolation{true}(u,t,gp)
end
  
### Curvefit
struct Curvefit{uType,tType,mType,cfType,FT,T} <: AbstractInterpolation{FT,T}
  u::uType
  t::tType
  m::mType
  c_f::cfType
  Curvefit{FT}(u,t,m,c_f) where FT = new{typeof(u),typeof(t),typeof(m),typeof(c_f),FT,eltype(u)}(u,t,m,c_f)
end

function Curvefit(u,t,m,p)
  c_f = curve_fit(m,t,u,p)
  Curvefit{true}(u,t,m,c_f)
end
