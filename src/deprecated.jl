#### Types and constructors ####

# Convenience constructors
export grayim
function grayim{T<:Union{UFixed,Bool}}(A::AbstractArray{T})
    Base.depwarn("grayim is deprecated, please use ColorView{Gray}(A), possibly in conjunction with ufixedview", :grayim)
    ColorView{Gray}(A)
end
grayim(A::Array{UInt8,2})  = grayim(reinterpret(UFixed8, A))
grayim(A::Array{UInt16,2}) = grayim(reinterpret(UFixed16, A))
grayim(A::Array{UInt8,3})  = grayim(reinterpret(UFixed8, A))
grayim(A::Array{UInt16,3}) = grayim(reinterpret(UFixed16, A))
grayim(A::AbstractArray{UInt8,2})  = grayim(ufixedview(A))
grayim(A::AbstractArray{UInt8,3})  = grayim(ufixedview(A))
grayim(A::AbstractArray{UInt16,2}) = grayim(ufixedview(U16, A))
grayim(A::AbstractArray{UInt16,3}) = grayim(ufixedview(U16, A))

export colorim
function colorim{T}(A::AbstractArray{T,3})
    if size(A, 1) == 4 || size(A, 3) == 4
        error("The array looks like a 4-channel color image. Please specify the colorspace explicitly (e.g. \"ARGB\" or \"RGBA\".)")
    end

    colorim(A, "RGB")
end
function colorim{T<:Fractional}(A::AbstractArray{T,3}, colorspace)
    Base.depwarn("colorim(A, colorspace) is deprecated, use ColorView{C}(A) instead, possibly in conjunction with permuteddimsview and/or ufixedview", :colorim)
    CT = getcolortype(colorspace, eltype(A))
    if 3 <= size(A, 1) <= 4 && 3 <= size(A, 3) <= 4
        error("Both first and last dimensions are of size 3 or 4; impossible to guess which is for color. Use the Image constructor directly.")
    elseif 3 <= size(A, 1) <= 4  # Image as returned by imread for regular 2D RGB images
        ColorView{CT}(A)
    elseif 3 <= size(A, 3) <= 4  # "Matlab"-style image, as returned by convert(Array, im).
        ColorView{CT}(permuteddimsview(A, (3,1,2)))
    else
        error("Neither the first nor the last dimension is of size 3. This doesn't look like an RGB image.")
    end
end
colorim(A::Array{UInt8,3},  colorspace) = colorim(reinterpret(UFixed8,  A), colorspace)
colorim(A::Array{UInt16,3}, colorspace) = colorim(reinterpret(UFixed16, A), colorspace)
colorim(A::AbstractArray{UInt8,3},  colorspace) = colorim(ufixedview(A), colorspace)
colorim(A::AbstractArray{UInt16,3}, colorspace) = colorim(ufixedview(U16, A), colorspace)

colorspacedict = Dict{String,Any}()
for ACV in (Color, AbstractRGB)
    for CV in subtypes(ACV)
        (length(CV.parameters) == 1 && !(CV.abstract)) || continue
        str = string(CV.name.name)
        colorspacedict[str] = CV
    end
end
function getcolortype{T}(str::String, ::Type{T})
    if haskey(colorspacedict, str)
        CV = colorspacedict[str]
        return CV{T}
    else
        if endswith(str, "A")
            CV = colorspacedict[str[1:end-1]]
            return coloralpha(CV){T}
        elseif startswith(str, "A")
            CV = colorspacedict[str[2:end]]
            return alphacolor(CV){T}
        else
            error("colorspace $str not recognized")
        end
    end
end

#### Data and traits ####

# NOTE: when this is deleted, modify ImagesMeta so it doesn't import this
export data
function data(img::AbstractArray)
    Base.depwarn("""

data(A) is deprecated for arrays that are not an ImageMeta. To avoid
using `data`, structure your code like this:

    function myfunction(img::AbstractArray, args...)
        # "real" algorithm goes here
    end
    myfunction(img::ImageMeta, args...) = myfunction(data(img), args...)

""", :data)
    img
end

# Using plain arrays, we used to have to make all sorts of guesses
# about colorspace and storage order. This was a big problem for
# three-dimensional images, image sequences, cameras with more than
# 16-bits, etc.

# Here are the two most important assumptions (see also colorspace below):
defaultarraycolordim = 3
# defaults for plain arrays ("vertical-major")
const yx = [:y, :x]
# order used in Cairo & most image file formats (with color as the very first dimension)
const xy = [:x, :y]
export spatialorder
function spatialorder(img::AbstractArray)
    Base.depwarn("spatialorder is deprecated for general AbstractArrays, please switch to ImagesAxes instead", :spatialorder)
    _spatialorder(img)
end
_spatialorder{M<:Matrix}(::Type{M}) = yx
_spatialorder(img::AbstractArray) = (sdims(img) == 2) ? _spatialorder(Matrix) : error("cannot guess spatial order for images with ", sdims(img), " spatial dimensions")

@deprecate isdirect(img::AbstractArray) true

export colorspace
function colorspace(img)
    Base.depwarn("""
colorspace(img) is deprecated, use eltype(img) instead, possibly in conjunction
with colorview(img)""", :colorspace)
    _colorspace(img)
end
_colorspace{C<:Colorant}(img::AbstractVector{C}) = ColorTypes.colorant_string(C)
_colorspace{C<:Colorant}(img::AbstractMatrix{C}) = ColorTypes.colorant_string(C)
_colorspace{C<:Colorant}(img::AbstractArray{C,3}) = ColorTypes.colorant_string(C)
_colorspace{C<:Colorant}(img::AbstractArray{C}) = ColorTypes.colorant_string(C)
@noinline _colorspace(img::AbstractVector{Bool}) = "Binary"  # noinlines are just for test coverage (julia bug)
@noinline _colorspace(img::AbstractMatrix{Bool}) = "Binary"
@noinline _colorspace(img::AbstractArray{Bool}) = "Binary"
@noinline _colorspace(img::AbstractArray{Bool,3}) = "Binary"
@noinline _colorspace(img::AbstractMatrix{UInt32}) = "RGB24"
@noinline _colorspace(img::AbstractVector) = "Gray"
@noinline _colorspace(img::AbstractMatrix) = "Gray"
_colorspace{T}(img::AbstractArray{T,3}) = (size(img, defaultarraycolordim) == 3) ? "RGB" : error("Cannot infer colorspace of Array, use a color eltype (e.g., colorview)")


export colordim
function colordim(img)
    Base.depwarn("colordim(img) is deprecated, use colorview(img) to represent as a color image", :colordim)
    _colordim(img)
end
_colordim{C<:Colorant}(img::AbstractArray{C}) = 0
_colordim(img::AbstractArray) = 0

export timedim
function timedim(img)
    Base.depwarn("timedim(img) is deprecated for general AbstractArrays, please switch to ImagesAxes", :timedim)
    return 0
end

export limits
function limits(img)
    Base.depwarn("limits(img) is deprecated, use (zero(T),one(T)) where T is the eltype", :limits)
    _limits(img)
end
_limits(img::AbstractArray{Bool}) = 0,1
_limits{T}(img::AbstractArray{T}) = zero(T), one(T)

export storageorder
function storageorder(img::AbstractArray)
    Base.depwarn("storageorder is deprecated, please switch to ImagesAxes and use `axisnames`", :storageorder)
    so = Array(Symbol, ndims(img))
    so[[coords_spatial(img)...]] = spatialorder(img)
    td = timedim(img)
    if td != 0
        so[td] = :t
    end
    so
end

# number of array elements used for each pixel/voxel
export ncolorelem
function ncolorelem{T}(img::AbstractArray{T})
    Base.depwarn("ncolorelem is deprecated, please encode as a color array (possibly with `colorview`) and use `length(eltype(img))`.\nNumeric arrays are assumed to be grayscale and will return 1.", :ncolorelem)
    T <: Colorant ? length(T) : 1
end

#### Utilities for writing "simple algorithms" safely ####
# If you don't feel like supporting multiple representations, call these

# Two-dimensional images
export assert2d
function assert2d(img::AbstractArray)
    Base.depwarn("assert2d is deprecated, write your algorithm as `myfunc{T}(img::AbstractArray{T,2}) instead", :assert2d)
    if ndims(img) != 2
        error("Only two-dimensional images are supported")
    end
end

# "Scalar color", either grayscale, RGB24, or an immutable type
export assert_scalar_color
function assert_scalar_color(img::AbstractArray)
    Base.depwarn("assert_scalar_color is deprecated and can be removed", :assert_scalar_color)
    nothing
end


# Spatial storage order
export isyfirst, isxfirst, assert_yfirst, assert_xfirst
"""
    isyfirst(img)

Return true if the first spatial dimension is `:y`. Supported only
if you use ImagesAxes.

See also: `isxfirst`, `assert_yfirst`.
"""
function isyfirst(img::AbstractArray)
    Base.depwarn("isyfirst is deprecated, please use ImagesAxes and test axisnames(img)[1] directly", :isyfirst)
    spatialorder(img)[1] == :y
end

"""
    assert_yfirst(img)

Throw an error if the first spatial dimension is not `:y`.
"""
function assert_yfirst(img)
    Base.depwarn("assert_yfirst is deprecated, please use ImagesAxes and test axisnames(img)[1] directly", :assert_yfirst)
    if !isyfirst(img)
        error("Image must have y as its first dimension")
    end
end

"""
    isxfirst(img)

Return true if the first spatial dimension is `:x`. Supported only
if you use ImagesAxes.

See also: `isyfirst`, `assert_xfirst`.
"""
function isxfirst(img::AbstractArray)
    Base.depwarn("isxfirst is deprecated, please use ImagesAxes and test axisnames(img)[1] directly", :isxfirst)
    spatialorder(img)[1] == :x
end

"""
    assert_xfirst(img)

Throw an error if the first spatial dimension is not `:x`.
"""
function assert_xfirst(img::AbstractArray)
    Base.depwarn("assert_xfirst is deprecated, please use ImagesAxes and test axisnames(img)[1] directly", :asset_xfirst)
    if !isxfirst(img)
        error("Image must have x as its first dimension")
    end
end

#### Permutations over dimensions ####

export spatialproperties
function spatialproperties(img::AbstractArray)
    Base.depwarn("spatialproperties is deprecated for any arrays other than ImageMeta", :spatialproperties)
    String[]
end

@deprecate spatialpermutation permutation

# Permute the dimensions of an image, also permuting the relevant properties. If you have non-default properties that are vectors or matrices relative to spatial dimensions, include their names in the list of spatialprops.
import Base: permutedims
@deprecate permutedims{S<:AbstractString}(img::StridedArray, pstr::Union{Vector{S}, Tuple{S,Vararg{S}}}, spatialprops::Vector=spatialproperties(img)) permutedims(img, map(Symbol, pstr), spatialprops)
@deprecate permutedims{S<:AbstractString}(img::AbstractArray, pstr::Union{Vector{S}, Tuple{S,Vararg{S}}}, spatialprops::Vector=spatialproperties(img)) permutedims(img, map(Symbol, pstr), spatialprops)

Base.permutedims{S<:Symbol}(img::StridedArray, pstr::Union{Vector{S}, Tuple{Vararg{S}}}, spatialprops::Vector = spatialproperties(img)) = error("not supported, please switch to ImagesAxes")
Base.permutedims{S<:Symbol}(img::AbstractArray, pstr::Union{Vector{S}, Tuple{Vararg{S}}}, spatialprops::Vector = spatialproperties(img)) = error("not supported, please switch to ImagesAxes")

### Functions ###
@deprecate raw rawview
@deprecate raw{C<:Colorant}(A::AbstractArray{C}) rawview(channelview(A))
@deprecate separate{C<:Colorant,N}(img::AbstractArray{C,N}) permuteddimsview(channelview(img), (ntuple(n->n+1, Val{N})..., 1))
if squeeze1
    @deprecate separate{C<:Color1,N}(img::AbstractArray{C,N}) channelview(img)
end
