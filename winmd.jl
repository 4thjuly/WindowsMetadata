# High level support for winmd metadataimport

function convertTypeToJulia(type::ELEMENT_TYPE)
    if type == ELEMENT_TYPE_I
        return Ptr{Cvoid}
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
end