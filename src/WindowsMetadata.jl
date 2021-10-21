# High level support for winmd metadataimport

module WindowsMetadata

include("metadataimport-wrapper.jl")

# TODO - rethink export of types, seems weird to "pollute" the caller
#   Maybe switch to using WindowsMetadata: WindowsMetadata as WMD and then use as WMD.HWND, WMD.LPARAM etc
# TODO make exportname macro
export Winmd, @L_str, convertClassFieldsToJuliaConsts, convertTypeToJulia, convertFunctionToJulia

import Base.@kwdef

macro L_str(s) transcode(Cwchar_t, s) end
macro exportname(name) 
    return :(export $name)
end

const Typemap = Dict{String, DataType}

struct Winmd
    mdi::CMetaDataImport
    prefix::String
    types::Typemap
end

# TODO - Support other winmd files
function Winmd(winmdname::String)
    mdd = metadataDispenser()
    path = joinpath(dirname(pathof(WindowsMetadata)), "$winmdname.winmd")
    mdi = metadataImport(mdd, path)
    Winmd(mdi, winmdname, Typemap())
end

function convertTypeToJulia(type::ELEMENT_TYPE)::Type
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
    elseif type == ELEMENT_TYPE_I
        return Int
    elseif type == ELEMENT_TYPE_U
        return UInt
    elseif type == ELEMENT_TYPE_VOID
        return Nothing
    end
    error("NYI: $type")
    return nothing
end

function convertTypeToJulia(winmd::Winmd, mdt::mdToken)::Type
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
        typename = getName(mdi, mdt)
        if isStruct(mdi, typename)
            return createStructType(winmd, typename)
        elseif isCallback(mdi, mdt)
            return Ptr{Cvoid}
        end
    end
    return Nothing
end

function convertTypeToJulia(winmd::Winmd, type::mdToken, typeattr::UInt32, arraylen::Int)::Type
    mdi = winmd.mdi
    if typeattr & TYPEATTR_PTR == TYPEATTR_PTR
        ptrtype = convertTypeToJulia(winmd, type)
        return Ptr{ptrtype}
    elseif typeattr & TYPEATTR_ARRAY == TYPEATTR_ARRAY
        arraytype = convertTypeToJulia(winmd, type)
        return NTuple{arraylen, arraytype}
    else
        return convertTypeToJulia(winmd, type);
    end
    # TODO - isValue
end

convertTypeToJulia(winmd::Winmd, name::String) = convertTypeToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$name"))
convertTypeToJulia(winmd::Winmd, location::String, typename::String) = convertTypeToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$location.$typename"))

function convertTypeToJulia(winmd::Winmd, location::String, names::Vector{String}) 
    types = Type[]
    for name in names
        push!(types, convertTypeToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$location.$name")))
    end
    return types
end

# Just take the last part of the winmd typename
function postDotSuffix(typename::String)
    lastdotpos = findlast(isequal('.'), typename)
    return typename[lastdotpos+1:end]
end

dotToUnderscore(s::String) = replace(s, '.' => '_')

# convertTypeNameToJulia(typename::String) = dotToUnderscore(typename)
convertTypeNameToJulia(typename::String) = postDotSuffix(typename)
convertTypeNameToJulia(typename::String, prefix::String) = replace(typename, "$(prefix)." => "") |> convertTypeNameToJulia

function createStructType(structname::String, fields::Vector{Tuple{String, Type}})
    fexps = [:($(Symbol(x[1]))::$(x[2])) for x in fields]
    sexp = quote 
        struct $(Symbol(structname))
            $(fexps...)
        end
    end
    eval(sexp)
    # @show structname
    # eval(Expr(:export, Symbol(structname)))
    @exportname structname
    return eval(Symbol(structname))
end

function createStructType(winmd::Winmd, wstructname::String)
    structtype = get(winmd.types, wstructname, nothing)
    if structtype !== nothing return structtype end

    mdi = winmd.mdi
    winfields = enumFields(mdi, wstructname)
    jfields = Vector{Tuple{String, Type}}(undef, 0)
    for winfield in winfields 
        name, sigblob = getFieldProps(mdi, winfield)
        jfield = convertTypeToJulia(winmd, sigblob)
        if jfield !== nothing
            push!(jfields, (name, jfield))
        end
    end
    jname = convertTypeNameToJulia(wstructname, winmd.prefix)
    structtype = createStructType(jname, jfields)
    winmd.types[wstructname] = structtype 
    return structtype
end

function convertTypeToJulia(winmd::Winmd, sigblob::Vector{COR_SIGNATURE})
    type, len, typeattr, arraylen = fieldSigblobToTypeInfo(sigblob)
    return convertTypeToJulia(winmd, type, typeattr, arraylen)
end

function convertClassFieldsToJulia(winmd::Winmd, classname::String, filter::Regex, jclassname::String)
    mdi = winmd.mdi
    fields = enumFields(mdi, "$(winmd.prefix).$classname")
    jfields = Tuple{String, Type}[]
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

function createConstExp(name::String, jfield::Type, val::Any)
    exp = :(const $(Symbol(name)) = $jfield($val))
end

function convertClassFieldsToJuliaConsts(winmd::Winmd, classname::String, filters::Vector{Regex})
    mdi = winmd.mdi
    fields = enumFields(mdi, "$(winmd.prefix).$classname")
    for field in fields
        name, sigblob, pval = getFieldProps(mdi, field)
        for filter in filters 
            if occursin(filter, name)
                jfield = convertTypeToJulia(winmd, sigblob)
                val = fieldValue(jfield, pval)
                createConstExp(name, jfield, val) |> eval
                eval(Expr(:export, Symbol(name)))
            end
        end
    end
    return nothing
end
convertClassFieldsToJuliaConsts(winmd::Winmd, classname::String, filter::Regex) = convertClassFieldsToJuliaConsts(winmd, classname, [filter])

function paramNamesAndAttrs(mdi::CMetaDataImport, params::Vector{mdParamDef})
    results = Tuple{String, DWORD}[]
    for param in params
        name, attr = getParamProps(mdi, param)
        push!(results, (name, attr))
    end
    return results
end

function convertParamTypesToJulia(winmd::Winmd, typeinfos::Vector{Tuple{mdToken, UInt32, Int}})
    jtypes = Type[]
    for typeinfo in typeinfos
        type, typeattr, arraylen = typeinfo
        jtype = convertTypeToJulia(winmd, type, typeattr, arraylen)
        # Covnvert ptr-to-thing param to ref-to-thing so ccall marshalling works properly  
        if typeattr & TYPEATTR_PTR == TYPEATTR_PTR
            jtype = supertype(jtype) # Ptr to Ref
        end
        push!(jtypes, jtype)
    end
    return jtypes
end 

function createCCall(mod::String, funcname::String, rettype::Type, params::Vector{Tuple{String, Type}}) # ::Function
    funcparamexp = [:($(Symbol(p[1]))::$(p[2])) for p in params]
    funcparamvals = [:($(Symbol(p[1]))) for p in params]
    funcparamtypes = Expr(:tuple, [(p[2]) for p in params]...)

    callexp = quote
        function $(Symbol(funcname))($(funcparamexp...))
            ccall($(Symbol(funcname), mod), $rettype, $funcparamtypes, $(funcparamvals...))
        end
    end

    eval(Expr(:export, Symbol(funcname)))
    return eval(callexp)
end

function convertFunctionToJulia(winmd::Winmd, mdclass::mdTypeDef, methodname::String)
    # @show methodname
    mdi = winmd.mdi
    mdgmh = findMethod(mdi, mdclass, methodname)
    # @show mdgmh methodname
    mref, importname = getPInvokeMap(mdi, mdgmh)
    modulename = getModuleRefProps(mdi, mref)
    sigblob = getMethodProps(mdi, mdgmh)
    typeinfos = methodSigblobToTypeInfos(sigblob)
    params = enumParams(mdi, mdgmh)
    # @show params
    namesAndAttrs = paramNamesAndAttrs(mdi, params)
    jtypes = convertParamTypesToJulia(winmd, typeinfos)
    # @show methodname modulename importname namesAndAttrs typeinfos jtypes

    # Convert params and pair. 
    # NB namesAndAttrs doesn't always have a return type first so fix that here
    funcparams = Tuple{String, Type}[]
    if namesAndAttrs[1][1] != ""
        insert!(namesAndAttrs, 1, ("", UInt32(0)))
    end
    for i = 2:length(namesAndAttrs)
        (name, attr) = namesAndAttrs[i]
        jtype = jtypes[i]
        if attr & CORPARAMATTR_PDOUT == CORPARAMATTR_PDOUT
            jtype = supertype(jtype)
        end

        push!(funcparams, (name, jtype))
    end

    # @show funcparams

    # Generate stub function
    return createCCall(modulename, methodname, jtypes[1], funcparams)
end

convertFunctionToJulia(winmd::Winmd, classname::String, methodname::String) = convertFunctionToJulia(winmd, findTypeDef(winmd.mdi, "$(winmd.prefix).$classname"), methodname)

function convertFunctionToJulia(winmd::Winmd, classname::String, methodnames::Vector{String})
    mdclass = findTypeDef(winmd.mdi, "$(winmd.prefix).$classname")
    for methodname in methodnames
        convertFunctionToJulia(winmd, mdclass, methodname)
    end
end

end # module
