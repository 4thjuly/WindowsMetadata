# High level support for winmd metadataimport

include("metadataimport-wrapper.jl")

import Base.@kwdef

struct Winmd
    mdi::COMWrapper{IMetaDataImport}
    types::Dict{String, DataType}
end

function Winmd()
    return Winmd(metadataDispenser() |> metadataImport, Dict{String, DataType}())
end

function convertPrimitiveTypeToJulia(type::ELEMENT_TYPE)
    if type == ELEMENT_TYPE_I
        return Ptr{Cvoid}
    elseif type == ELEMENT_TYPE_I2
        return Int16
    elseif type == ELEMENT_TYPE_U2
        return UInt16
    elseif type == ELEMENT_TYPE_I4
        return Int32
    elseif type == ELEMENT_TYPE_U4
        return UInt32
    end
    # TBD
    throw("Not yet implemented")
end

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

# TODO Handle multiple fields, handle recursion
function createStructType(winmd::Winmd, structname::String)
    mdi = winmd.mdi
    undotname = convertTypeNameToJulia(structname)
    structtype = get(winmd.types, structname, nothing)
    if structtype != nothing
        return structtype
    else
        fps = fieldProps(mdi, enumFields(mdi, findTypeDef(mdi, structname))[1])
        typeinfo = fps.sigblob |> fieldSigblobtoTypeInfo
        fieldtype = convertPrimitiveTypeToJulia(ELEMENT_TYPE(typeinfo.type))
        structtype = createStructType(undotname, [(fps.name, fieldtype)])
        winmd.types[structname] = structtype 
    end
    return nothing
end