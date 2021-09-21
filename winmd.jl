# High level support for winmd metadataimport

include("metadataimport-wrapper.jl")

import Base.@kwdef

const Typemap = Dict{String, DataType}

struct Winmd
    mdi::CMetaDataImport
    types::Typemap
end

function Winmd()
    return Winmd(metadataDispenser() |> metadataImport, Typemap())
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
    end
    return nothing
end

function convertTypeToJulia(mdi::CMetaDataImport, mdt::mdToken)::DataType
    if mdt & UInt32(TOKEN_TYPE_MASK) == 0x00000000
        # Primitive types
        return convertTypeToJulia(ELEMENT_TYPE(mdt))
    else
        # Typedef or TypeRef
        name = getName(mdi, mdt)
        if isStruct(mdi, name)
            return createStructType(mdi, name)
        elseif isCallback(mdi, mdt)
            return Ptr{Cvoid}
        end
    end
    return Nothing
end

function convertTypeToJulia(mdi::CMetaDataImport, mdt::mdToken, isPtr::Bool, isValue::Bool)::DataType
    # TODO - isValue
    if isPtr
        ptrtype = convertTypeToJulia(mdi, mdt);
        return Ptr{ptrtype}
    else
        return convertTypeToJulia(mdi, mdt);
    end
end

convertTypeToJulia(mdi::CMetaDataImport, name::String) = convertTypeToJulia(mdi, findTypeDef(mdi, name))
convertTypeToJulia(winmd::Winmd, name::String) = convertTypeToJulia(winmd.mdi, name)

convertTypeNameToJulia(name::String) = replace(name, '.' => '_')

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

# TODO Handle recursion
function createStructType(winmd::Winmd, structname::String)
    createStructType(winmd.mdi, structname)
end

function createStructType(mdi::CMetaDataImport, structname::String)
    undotname = convertTypeNameToJulia(structname)
    structtype = get(winmd.types, structname, nothing)
    if structtype !== nothing
        return structtype
    else
        winfields = enumFields(mdi, findTypeDef(mdi, structname))
        jfields = Vector{Tuple{String, DataType}}(undef, 0)
        for winfield in winfields 
            props = fieldProps(mdi, winfield)
            typeinfo = props.sigblob |> fieldSigblobtoTypeInfo
            jfield = convertTypeToJulia(mdi, typeinfo.type, typeinfo.isPtr, typeinfo.isValueType)
            if jfield !== nothing
                push!(jfields, (props.name, jfield))
            end
        end
        structtype = createStructType(undotname, jfields)
        winmd.types[structname] = structtype 
        return structtype
    end
end