#=

Utility functions that have nowhere obvious to go.

=#

"""
    svector(f,n)

Create an `SVector` of length n, computing each element as f(i), where i is the
index of the element.
"""
svector(f,n)=  ntuple(f,n) |> SVector

"""
    interface_method(x)

A method of an `abstract type` for which concrete subtypes are expected to
provide an implementation.
"""
function interface_method(T::DataType)
    return error("this method needs to be implemented by the concrete subtype $T.")
end
interface_method(x) = interface_method(typeof(x))

"""
    standard_basis_vector(k, ::Val{N})

Create an `SVector` of length N with a 1 in the kth position and zeros elsewhere.
"""
standard_basis_vector(k, n::Val{N}) where {N} = svector(i-> i == k ? 1 : 0, n)

"""
    ambient_dimension(x)

Dimension of the ambient space where `x` lives. For geometrical objects this can
differ from its [`geometric_dimension`](@ref); for example a triangle in `ℝ³`
has ambient dimension `3` but geometric dimension `2`, while a curve in `ℝ³` has
ambient dimension 3 but geometric dimension 1.
"""
function ambient_dimension end

"""
    geometric_dimension(x)

NNumber of degrees of freedom necessary to locally represent the geometrical
object. For example, lines have geometric dimension of 1 (whether in `ℝ²` or in
`ℝ³`), while surfaces have geometric dimension of 2.
"""
function geometric_dimension end

"""
    return_type(f[,args...])

The type returned by `f(args...)`, where `args` is a tuple of types. Falls back
to `Base.promote_op` by default.

A functors of type `T` with a knonw return type should extend
`return_type(::T,args...)` to avoid relying on `promote_op`.
"""
function return_type(f, args...)
    @debug "using `Base.promote_op` to infer return type. Consider defining `return_type(::typeof($f),args...)`."
    return Base.promote_op(f, args...)
end

"""
    domain(f)

Given a function-like object `f: Ω → R`, return `Ω`.
"""
function domain end

"""
    image(f)

Given a function-like object `f: Ω → R`, return `f(Ω)`.
"""
function image end

"""
    _integration_measure(J::AbstractMatrix)

Given the Jacobian matrix `J` of a transformation `f : ℝᴹ → ℝᴺ`, compute the
integration measure `√det(JᵀJ)`.
"""
function _integration_measure(jac::AbstractMatrix)
    M, N = size(jac)
    if M == N
        abs(det(jac)) # cheaper when `M=N`
    else
        g = det(transpose(jac) * jac)
        g < -sqrt(eps()) && (@warn "negative integration measure g=$g")
        g = max(g, 0)
        sqrt(g)
    end
end

"""
    _normal(jac::SMatrix{M,N})

Given a an `M` by `N` matrix representing the jacobian of a codimension one
object, compute the normal vector.
"""
function _normal(jac::SMatrix{N,M}) where {N,M}
    msg = "computing the normal vector requires the element to be of co-dimension one."
    @assert (N - M == 1) msg
    if M == 1 # a line in 2d
        t = jac[:, 1] # tangent vector
        n = SVector(t[2], -t[1]) |> normalize
        return n
    elseif M == 2 # a surface in 3d
        t₁ = jac[:, 1]
        t₂ = jac[:, 2]
        n = cross(t₁, t₂) |> normalize
        return n
    else
        notimplemented()
    end
end

# helper functions to retrieve extensions
"""
    get_gmsh_extension()

Get the Gmsh extension, if available.
"""
function get_gmsh_extension()
    ext = Base.get_extension(Inti,:IntiGmshExt)
    isnothing(ext) && error("Gmsh extension not available. Try `using Gmsh` first.")
    return ext
end

"""
    get_makie_extension()

Get the Makie extension, if available.
"""
function get_makie_extension()
    ext = Base.get_extension(Inti,:IntiMakieExt)
    isnothing(ext) && error("Makie extension not available. Try e.g. `using CairoMakie` first.")
    return ext
end

"""
    get_vtk_extension()

Get the VTK extension, if available.
"""
function get_vtk_extension()
    ext = Base.get_extension(Inti,:IntiVTKExt)
    isnothing(ext) && error("VTK extension not available. Try e.g. `using WriteVTK` first.")
    return ext
end