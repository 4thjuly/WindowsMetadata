# High level support for winmd metadataimport

include("metadataimport-wrapper.jl")

import Base.@kwdef

const Typemap = Dict{String, DataType}

struct Winmd
    mdi::CMetaDataImport
    prefix::String
    types::Typemap
end

function Winmd(prefix::String)
    return Winmd(metadataDispenser() |> metadataImport, prefix, Typemap())
end

function convertTypeToJulia(type::ELEMENT_TYPE)::DataType
    if type == ELEMENT_TYPE_I
        return Ptr{Cvoid}
    elseif type == ELEMENT_TYPE_I1
        return Int8
    elseif type == ELEMENT_TYPE_U1
        return UInt8
    elseif type == ELEMENT_TYPE_I2
        return Int16
    elseif type == ELEMENT_TYPE_U2
        return UInt16
    elseif type == ELEMENT_TYPE_I4
        return Int32
    elseif type == ELEMENT_TYPE_U4
        return UInt32
    elseif type == ELEMENT_TYPE_R4
        return Float32
    elseif type == ELEMENT_TYPE_R8
            return Float64
    end
    error("NYI: $type")
    return nothing
end

function convertTypeToJulia(winmd::Winmd, mdt::mdToken)::DataType
    mdi = winmd.mdi
    if mdt & UInt32(TOKEN_TYPE_MASK) == 0x00000000
        if ELEMENT_TYPE(mdt) == ELEMENT_TYPE_ARRAY
            error("NYI")
        else
            # Primitive types
            return convertTypeToJulia(ELEMENT_TYPE(mdt))
        end
    else
        # Typedef or TypeRef
        name = getName(mdi, mdt)
        if isStruct(mdi, name)
            return createStructType(winmd, name)
        elseif isCallback(mdi, mdt)
            return Ptr{Cvoid}
        end
    end
    return Nothing
end

function convertTypeToJulia(winmd::Winmd, type::mdToken, isPtr::Bool, isValue::Bool, isArray::Bool, arraylen::Int)::DataType
    mdi = winmd.mdi
    # TODO - isValue
    if isPtr
        ptrtype = convertTypeToJulia(winmd, type)
        return Ptr{ptrtype}
    elseif isArray
        arraytype = convertTypeToJulia(winmd, type)
        return NTuple{arraylen, arraytype}
    else
        return convertTypeToJulia(winmd, type);
    end
end

convertTypeToJulia(winmd::Winmd, name::String) = convertTypeToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$name"))

convertTypeNameToJulia(name::String) = replace(name, '.' => '_')
convertTypeNameToJulia(name::String, prefix::String) = replace(name, "$(prefix)." => "") |> convertTypeNameToJulia

function createStructType(structname::String, fields::Vector{Tuple{String, DataType}})
    fexps = [:($(Symbol(x[1]))::$(x[2])) for x in fields]
    sexp = quote 
        struct $(Symbol(structname))
            $(fexps...)
        end
    end
    # dump(sexp)
    eval(sexp)
    return eval(Symbol(structname))
end

function createStructType(winmd::Winmd, wstructname::String)
    structtype = get(winmd.types, wstructname, nothing)
    if structtype !== nothing return structtype end

    mdi = winmd.mdi
    winfields = enumFields(mdi, wstructname)
    jfields = Vector{Tuple{String, DataType}}(undef, 0)
    for winfield in winfields 
        name, sigblob = getFieldProps(mdi, winfield)
        jfield = convertTypeToJulia(winmd, sigblob)
        if jfield !== nothing
            push!(jfields, (name, jfield))
        end
    end
    undotname = convertTypeNameToJulia(wstructname, winmd.prefix)
    structtype = createStructType(undotname, jfields)
    winmd.types[wstructname] = structtype 
    return structtype
end

function convertTypeToJulia(winmd::Winmd, sigblob::Vector{COR_SIGNATURE})
    type, len, isPtr, isValueType, isArray, arraylen = fieldSigblobToTypeInfo(sigblob)
    return convertTypeToJulia(winmd, type, isPtr, isValueType, isArray, arraylen)
end

# function convertClassFieldsToJulia(winmd::Winmd, classname::String, prefixfilter::String="")
#     classtype = get(winmd.types, classname, nothing)
#     if classtype !== nothing return classtype end

#     mdi = winmd.mdi
#     fields = enumFields(mdi, "$(winmd.prefix).$classname")
#     jfields = Tuple{String, DataType}[]
#     jinitvals = Any[]
#     for field in fields
#         name, sigblob, pval = fieldProps(mdi, field)
#         if length(prefixfilter) == 0 || startswith(name, prefixfilter)
#             jfield = convertTypeToJulia(winmd, sigblob)
#             val = fieldValue(jfield, pval)
#             push!(jfields, (name, jfield))
#             push!(jinitvals, val)
#             # @show name jfield val
#         end
#     end
#     @show length(jfields)
#     undotname = convertTypeNameToJulia(classname, winmd.prefix)
#     # jclassname = "$(undotname)_$(prefixfilter)"
#     jclassname = prefixfilter
#     @show jclassname

#     structtype = createStructType(jclassname, jfields)
#     @show structtype
#     winmd.types["$(winmd.prefix).$classname"] = structtype 

#     # Create initialized instance
#     inst = Base.invokelatest(structtype, jinitvals...)
#     return inst
# end

function convertClassFieldsToJulia(winmd::Winmd, classname::String, filter::Regex, jclassname::String)
    mdi = winmd.mdi
    fields = enumFields(mdi, "$(winmd.prefix).$classname")
    jfields = Tuple{String, DataType}[]
    jinitvals = Any[]
    for field in fields
        name, sigblob, pval = getFieldProps(mdi, field)
        if occursin(filter, name)
            jfield = convertTypeToJulia(winmd, sigblob)
            val = fieldValue(jfield, pval)
            push!(jfields, (name, jfield))
            push!(jinitvals, val)
            # @show name jfield val
        end
    end
    # @show length(jfields)
    # @show jclassname

    structtype = createStructType(jclassname, jfields)
    # @show structtype

    # NB Don't cache these types of partial classes, return a specific instance instead
    return Base.invokelatest(structtype, jinitvals...)
end

function convertFunctionToJulia(winmd::Winmd, class::mdTypeDef, methodname::String)
    # Get function params
    # Convert to julia types (recurse to create needed types)
    # Simple types, ptrs
    # out types need refs, make the caller pass them in
end

convertFunctionToJulia(winmd::Winmd, classname::String, methodname::String) = convertFunctionToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$classname"), methodname)
