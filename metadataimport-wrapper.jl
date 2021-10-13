# Low level wrapper for metadataimport

import Base.@kwdef

const DEFAULT_BUFFER_LEN = 64*1024
const S_OK = 0x00000000
const CorOpenFlags_ofRead = 0x00000000

const SYSTEM_VALUETYPE_STR = "System.ValueType"
const SYSTEM_MULTICAST_DELEGATE_STR = "System.MulticastDelegate"

const Byte = UInt8
const HRESULT = UInt32
const ULONG32 = UInt32
const ULONG = UInt32
const DWORD = UInt32
const mdToken = ULONG32
const mdTypeDef = mdToken
const mdMethodDef = mdToken
const mdModuleRef = mdToken
const mdParamDef = mdToken
const mdSignature = mdToken
const mdTypeRef = mdToken
const mdTypeSpec = mdToken
const mdFieldDef = mdToken
const mdTokenNil = mdToken(0)

const UVCP_CONSTANT = Ptr{Cvoid}
const HCORENUM = Ptr{Cvoid}
const COR_SIGNATURE = UInt8

struct HRESULT_FAILED <: Exception 
    hresult::HRESULT
end

@enum TOKEN_TYPE::UInt32 begin
    TOKEN_TYPE_MODULE               = 0x00000000       
    TOKEN_TYPE_TYPEREF              = 0x01000000       
    TOKEN_TYPE_TYPEDEF              = 0x02000000       
    TOKEN_TYPE_FIELDDEF             = 0x04000000       
    TOKEN_TYPE_METHODDEF            = 0x06000000       
    TOKEN_TYPE_PARAMDEF             = 0x08000000       
    TOKEN_TYPE_INTERFACEIMPL        = 0x09000000       
    TOKEN_TYPE_MEMBERREF            = 0x0A000000       
    TOKEN_TYPE_CUSTOMATTRIBUTE      = 0x0C000000       
    TOKEN_TYPE_PERMISSION           = 0x0E000000       
    TOKEN_TYPE_SIGNATURE            = 0x11000000       
    TOKEN_TYPE_EVENT                = 0x14000000       
    TOKEN_TYPE_PROPERTY             = 0x17000000       
    TOKEN_TYPE_METHODIMPL           = 0x19000000       
    TOKEN_TYPE_MODULEREF            = 0x1A000000       
    TOKEN_TYPE_TYPESPEC             = 0x1B000000       
    TOKEN_TYPE_ASSEMBLY             = 0x20000000       
    TOKEN_TYPE_ASSEMBLYREF          = 0x23000000       
    TOKEN_TYPE_FILE                 = 0x26000000       
    TOKEN_TYPE_EXPORTEDTYPE         = 0x27000000       
    TOKEN_TYPE_MANIFESTRESOURCE     = 0x28000000       
    TOKEN_TYPE_GENERICPARAM         = 0x2A000000       
    TOKEN_TYPE_METHODSPEC           = 0x2B000000       
    TOKEN_TYPE_GENERICPARAMCONSTRAINT = 0x2C000000
    TOKEN_TYPE_STRING               = 0x70000000       
    TOKEN_TYPE_NAME                 = 0x71000000       
    TOKEN_TYPE_BASETYPE             = 0x72000000  
    TOKEN_TYPE_MASK                 = 0xFF000000 
end

struct GUID
    Data1::Culong
    Data2::Cushort
    Data3::Cushort
    Data4::NTuple{8,Byte}
end

const CLSID = GUID
const IID = GUID

parse_hexbytes(s::String) = parse(Byte, s, base = 16)

# Guid of form 12345678-0123-5678-0123-567890123456
macro guid_str(s)
    GUID(parse(Culong, s[1:8], base = 16),   # 12345678
        parse(Cushort, s[10:13], base = 16), # 0123
        parse(Cushort, s[15:18], base = 16), # 5678
        (parse_hexbytes(s[20:21]),           # 0123
            parse_hexbytes(s[22:23]), 
            parse_hexbytes(s[25:26]),        # 567890123456
            parse_hexbytes(s[27:28]), 
            parse_hexbytes(s[29:30]), 
            parse_hexbytes(s[31:32]), 
            parse_hexbytes(s[33:34]), 
            parse_hexbytes(s[35:36])))
end

const CLSID_CorMetaDataDispenser = guid"E5CB7A31-7512-11d2-89CE-0080C792E5D8"
const IID_IMetaDataDispenser = guid"809C652E-7396-11D2-9771-00A0C9B4D50C"
const IID_IMetaDataImport = guid"7DAC8207-D3AE-4C75-9B67-92801A497D44"

struct PVtbl{T}
    value::Ptr{T}
end
const COMObject{T} = Ptr{PVtbl{T}}

struct COMWrapper{T}
    punk::COMObject{T}
end

getVtbl(cw::COMWrapper{T}) where T = unsafe_load(unsafe_load(cw.punk).value)

struct IUnknownVtbl
    QueryInterface::Ptr{Cvoid}
    AddRef::Ptr{Cvoid}
    Release::Ptr{Cvoid}
end

# TODO - Make Interface definitions a macro?
# - Create the vtbl, prepend other interface (eg IUnknown) and define the IID_ ala DECLARE_INTERFACE_IID 
# @declare_interface_iid IMetaDataDispenser IUnknown "7DAC8207-D3AE-4C75-9B67-92801A497D44"
#     ...
# end

struct IMetaDataDispenserVtbl
    iUnknown::IUnknownVtbl
    DefineScope::Ptr{Cvoid}
    OpenScope::Ptr{Cvoid}
    OpenScopeOnMemmory::Ptr{Cvoid}
end
const CWMetaDataDispenser = COMWrapper{IMetaDataDispenserVtbl}
const CMetaDataDispenser = COMObject{IMetaDataDispenserVtbl}


function metadataDispenser()
    rpmdd = Ref(CMetaDataDispenser(C_NULL))
    res = @ccall "Rometadata".MetaDataGetDispenser( 
        Ref(CLSID_CorMetaDataDispenser)::Ptr{Cvoid}, 
        Ref(IID_IMetaDataDispenser)::Ptr{Cvoid}, 
        rpmdd::Ref{CMetaDataDispenser}
        )::HRESULT
    if res == S_OK
        return COMWrapper{IMetaDataDispenserVtbl}(rpmdd[])
    end
    throw(HRESULT_FAILED(res))
end

struct IMetaDataImportVtbl
    iUnknown::IUnknownVtbl
    CloseEnum::Ptr{Cvoid}         
    CountEnum::Ptr{Cvoid} 
    ResetEnum::Ptr{Cvoid} 
    EnumTypeDefs::Ptr{Cvoid} 
    EnumInterfaceImpls::Ptr{Cvoid} 
    EnumTypeRefs::Ptr{Cvoid} 
    FindTypeDefByName::Ptr{Cvoid} 
    GetScopeProps::Ptr{Cvoid} 
    GetModuleFromScope::Ptr{Cvoid} 
    GetTypeDefProps::Ptr{Cvoid} 
    GetInterfaceImplProps::Ptr{Cvoid} 
    GetTypeRefProps::Ptr{Cvoid} 
    ResolveTypeRef::Ptr{Cvoid} 
    EnumMembers::Ptr{Cvoid} 
    EnumMembersWithName::Ptr{Cvoid} 
    EnumMethods::Ptr{Cvoid} 
    EnumMethodsWithName::Ptr{Cvoid} 
    EnumFields::Ptr{Cvoid} 
    EnumFieldsWithName::Ptr{Cvoid} 
    EnumParams::Ptr{Cvoid} 
    EnumMemberRefs::Ptr{Cvoid} 
    EnumMethodImpls::Ptr{Cvoid} 
    EnumPermissionSets::Ptr{Cvoid} 
    FindMember::Ptr{Cvoid} 
    FindMethod::Ptr{Cvoid} 
    FindField::Ptr{Cvoid} 
    FindMemberRef::Ptr{Cvoid} 
    GetMethodProps::Ptr{Cvoid} 
    GetMemberRefProps::Ptr{Cvoid} 
    EnumProperties::Ptr{Cvoid} 
    EnumEvents::Ptr{Cvoid} 
    GetEventProps::Ptr{Cvoid} 
    EnumMethodSemantics::Ptr{Cvoid} 
    GetMethodSemantics::Ptr{Cvoid} 
    GetClassLayout::Ptr{Cvoid} 
    GetFieldMarshal::Ptr{Cvoid} 
    GetRVA::Ptr{Cvoid} 
    GetPermissionSetProps::Ptr{Cvoid} 
    GetSigFromToken::Ptr{Cvoid} 
    GetModuleRefProps::Ptr{Cvoid} 
    EnumModuleRefs::Ptr{Cvoid} 
    GetTypeSpecFromToken::Ptr{Cvoid} 
    GetNameFromToken::Ptr{Cvoid} 
    EnumUnresolvedMethods::Ptr{Cvoid} 
    GetUserString::Ptr{Cvoid} 
    GetPinvokeMap::Ptr{Cvoid} 
    EnumSignatures::Ptr{Cvoid} 
    EnumTypeSpecs::Ptr{Cvoid} 
    EnumUserStrings::Ptr{Cvoid} 
    GetParamForMethodIndex::Ptr{Cvoid} 
    EnumCustomAttributes::Ptr{Cvoid} 
    GetCustomAttributeProps::Ptr{Cvoid} 
    FindTypeRef::Ptr{Cvoid} 
    GetMemberProps::Ptr{Cvoid} 
    GetFieldProps::Ptr{Cvoid} 
    GetPropertyProps::Ptr{Cvoid} 
    GetParamProps::Ptr{Cvoid} 
    GetCustomAttributeByName::Ptr{Cvoid} 
    IsValidToken::Ptr{Cvoid} 
    GetNestedClassProps::Ptr{Cvoid} 
    GetNativeCallConvFromSig::Ptr{Cvoid} 
    IsGlobal::Ptr{Cvoid} 
end

const CWMetaDataImport = COMWrapper{IMetaDataImportVtbl}
const CMetaDataImport = COMObject{IMetaDataImportVtbl}

function metadataImport(mdd::CWMetaDataDispenser)
    vtbl = getVtbl(mdd)
    rpmdi = Ref(Ptr{PVtbl{IMetaDataImportVtbl}}(C_NULL))
    res = @ccall $(vtbl.OpenScope)(
        mdd.punk::Ref{PVtbl{IMetaDataDispenserVtbl}}, 
        "Windows.Win32.winmd"::Cwstring,
        CorOpenFlags_ofRead::Cuint, 
        Ref(IID_IMetaDataImport)::Ptr{Cvoid}, 
        rpmdi::Ref{Ptr{PVtbl{IMetaDataImportVtbl}}}
        )::HRESULT
    if res == S_OK
        return COMWrapper{IMetaDataImportVtbl}(rpmdi[])
    end
    throw(HRESULT_FAILED(res))
end

function findTypeDef(mdi::CWMetaDataImport, name::String)::mdToken
    vtbl = getVtbl(mdi)
    rStructToken = Ref(mdToken(0))
    res = @ccall $(vtbl.FindTypeDefByName)(
        mdi.punk::Ref{PVtbl{IMetaDataImportVtbl}}, 
        name::Cwstring, 
        mdTokenNil::mdToken, 
        rStructToken::Ref{mdToken}
        )::HRESULT
    if res == S_OK
        return rStructToken[]
    end
    return mdTokenNil
end

function findMethod(mdi::CWMetaDataImport, td::mdTypeDef, methodName::String)
    vtbl = getVtbl(mdi)
    rmethodDef = Ref(mdToken(0))
    res = @ccall $(vtbl.FindMethod)(
        mdi.punk::Ref{PVtbl{IMetaDataImportVtbl}}, 
        td::mdTypeDef,
        methodName::Cwstring, 
        C_NULL::Ref{Cvoid}, 
        0::ULONG, 
        rmethodDef::Ref{mdToken}
        )::HRESULT 
    if res == S_OK
        return rmethodDef[]
    end
    return mdTokenNil
end

# function getPInvokeMap(mdi::CWMetaDataImport, md::mdMethodDef)
#     rflags = Ref(DWORD(0))
#     importname = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rnameLen = Ref(ULONG(0))
#     rmoduleRef = Ref(mdModuleRef(0))
#     res = @ccall $(getVtbl(mdi).GetPinvokeMap)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         md::mdMethodDef, 
#         rflags::Ref{DWORD},
#         importname::Ref{Cwchar_t},
#         length(importname)::ULONG, 
#         rnameLen::Ref{ULONG}, 
#         rmoduleRef::Ref{mdModuleRef}
#         )::HRESULT
#     if res == S_OK
#         return (rmoduleRef[], transcode(String, importname[begin:rnameLen[]-1]))
#     end
#     return (mdTokenNil, "")
# end

# function getModuleRefProps(mdi::CWMetaDataImport, mr::mdModuleRef)
#     modulename = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rmodulanameLen = Ref(ULONG(0))
#     res = @ccall $(getVtbl(mdi).GetModuleRefProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         mr::mdModuleRef,
#         modulename::Ref{Cwchar_t},
#         length(modulename)::ULONG,
#         rmodulanameLen::Ref{ULONG}
#         )::HRESULT
#     if res == S_OK
#         return transcode(String, modulename[begin:rmodulanameLen[]-1])
#     end
#     return ""
# end

# function getParamForMethodIndex(mdi::CWMetaDataImport, md::mdMethodDef, i::Int)
#     rparamDef = Ref(mdParamDef(0))
#     res = @ccall $(getVtbl(mdi).GetParamForMethodIndex)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         md::mdMethodDef,
#         ULONG(i)::ULONG,
#         rparamDef::Ref{mdParamDef}
#     )::HRESULT
#     if res == S_OK
#         return rparamDef[]
#     end
#     return mdTokenNil
# end

# const CorParamAttr_pdIn                        =   0x00000001
# const CorParamAttr_pdOut                       =   0x00000002  
# const CorParamAttr_pdOptional                  =   0x00000010  
# const CorParamAttr_pdReservedMask              =   0x0000f000  
# const CorParamAttr_pdHasDefault                =   0x00001000  
# const CorParamAttr_pdHasFieldMarshal           =   0x00002000  
# const CorParamAttr_pdUnused                    =   0x0000cfe0  

# # const CORPARAMATTR_PDIN                        =   0x00000001
# # const CORPARAMATTR_PDOUT                       =   0x00000002  
# # const CORPARAMATTR_PDOPTIONAL                  =   0x00000010  
# # const CORPARAMATTR_PDRESERVEDMASK              =   0x0000f000  
# # const CORPARAMATTR_PDHASDEFAULT                =   0x00001000  
# # const CORPARAMATTR_PDHASFIELDMARSHAL           =   0x00002000  
# # const CORPARAMATTR_PDUNUSED                    =   0x0000cfe0  

# function getParamProps(mdi::CWMetaDataImport, paramDef::mdParamDef)
#     paramName = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rparamMethodDef = Ref(mdMethodDef(0))
#     rparamNameLen = Ref(ULONG(0))
#     rseq = Ref(ULONG(0))
#     rattr = Ref(DWORD(0))
#     rcplustypeFlag = Ref(DWORD(0))
#     rpvalue = Ptr{Cvoid}(0)
#     rcchValue = Ref(ULONG(0))
#     res = @ccall $(getVtbl(mdi).GetParamProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         paramDef::mdParamDef,
#         rparamMethodDef::Ref{mdMethodDef},
#         rseq::Ref{ULONG},
#         paramName::Ref{Cwchar_t},
#         length(paramName)::ULONG,
#         rparamNameLen::Ptr{ULONG},
#         rattr::Ptr{DWORD},
#         rcplustypeFlag::Ptr{DWORD},
#         rpvalue::Ptr{Cvoid},
#         rcchValue::Ptr{ULONG}
#         )::HRESULT
#     if res == S_OK
#         return transcode(String, paramName[begin:rparamNameLen[]-1]), rattr[]
#     end
#     return "", 0
# end

# function getMethodProps(mdi::CWMetaDataImport, methodDef::mdMethodDef)
#     rclass = Ref(mdTypeDef(0))
#     methodName = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rmethodNameLen = Ref(ULONG(0))
#     rattr = Ref(DWORD(0))
#     rpsig = Ref(Ptr{COR_SIGNATURE}(C_NULL))
#     rsigLen = Ref(ULONG(0))
#     rrva = Ref(ULONG(0))
#     rflags = Ref(DWORD(0))
#     res = @ccall $(getVtbl(mdi).GetMethodProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         methodDef::mdMethodDef,
#         rclass::Ref{mdTypeDef},
#         methodName::Ref{Cwchar_t},
#         length(methodName)::ULONG,
#         rmethodNameLen::Ref{ULONG},
#         rattr::Ref{DWORD},
#         rpsig::Ref{Ptr{COR_SIGNATURE}},
#         rsigLen::Ref{ULONG},
#         rrva::Ref{ULONG},
#         rflags::Ref{DWORD}
#         )::HRESULT
#     if res == S_OK
#         return unsafe_wrap(Vector{COR_SIGNATURE}, Ptr{UInt8}(rpsig[]), rsigLen[])
#     end
#     throw(HRESULT_FAILED(res))
# end

# function uncompress(sig::AbstractVector{COR_SIGNATURE})
#     val::UInt32 = UInt32(0)
#     len = 0
#     if sig[1] & 0x80 == 0x00
#         val = UInt32(sig[1])
#         len = 1
#     elseif sig[1] & 0xC0 == 0x80
#         val = UInt32(sig[1] & 0x3F) << 8 | UInt32(sig[2])
#         len = 2
#     elseif sig[1] & 0xE0 == 0xC0
#         val = UInt32(sig[1] & 0x1f) << 24 | UInt32(sig[2]) << 16 | UInt32(sig[3]) << 8 | UInt32(sig[4])
#         len = 4
#     else
#         error("Bad signature")
#     end
#     return (val, len)
# end

# function uncompressToken(sig::AbstractVector{COR_SIGNATURE})
#     val, len = uncompress(sig)
#     tok::mdToken = mdTokenNil
#     if val & 0x03 == 0x00
#         tok = mdTypeDef(UInt32(TOKEN_TYPE_TYPEDEF) | (val >> 2))
#     elseif val & 0x03 == 0x01
#         tok = mdTypeRef(UInt32(TOKEN_TYPE_TYPEREF) | (val >> 2))
#     elseif val & 0x03 == 0x02
#         tok = mdTypeDef(UInt32(TOKEN_TYPE_TYPESPEC) | (val >> 2))
#     end
#     return tok, len
# end

# # check
# function isValidToken(mdi::CWMetaDataImport, tok::mdToken)::Bool
#     return @ccall $(getVtbl(mdi).IsValidToken)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         tok::mdToken
#         )::Bool
# end

# function getTypeRefName(mdi::CWMetaDataImport, tr::mdTypeRef)::String
#     rscope = Ref(mdToken(0))
#     name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rnameLen = Ref(ULONG(0))
#     res = @ccall $(getVtbl(mdi).GetTypeRefProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         tr::mdTypeRef,
#         rscope::Ref{mdToken},
#         name::Ref{Cwchar_t},
#         length(name)::ULONG,
#         rnameLen::Ref{ULONG}
#         )::HRESULT
#     if res == S_OK
#         return transcode(String, name[begin:rnameLen[]-1])
#     end
#     return ""
# end

# function getName(mdi::CWMetaDataImport, mdt::mdToken)::String
#     if mdt & UInt32(TOKEN_TYPE_TYPEDEF) == UInt32(TOKEN_TYPE_TYPEDEF)
#         props = getTypeDefProps(mdi, mdt) 
#         return props.name
#     elseif mdt & UInt32(TOKEN_TYPE_TYPEREF) == UInt32(TOKEN_TYPE_TYPEREF)
#         return getTypeRefName(mdi, mdt)
#     else
#         return ""
#     end
# end

# function findTypeDef(mdi::CWMetaDataImport, name::String)::mdToken
#     rStructToken = Ref(mdToken(0))
#     res = @ccall $(getVtbl(mdi).FindTypeDefByName)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         name::Cwstring, 
#         mdTokenNil::mdToken, 
#         rStructToken::Ref{mdToken}
#         )::HRESULT
#     if res == S_OK
#         return rStructToken[]
#     end
#     return mdTokenNil
# end

# function getTypeDefProps(mdi::CWMetaDataImport, td::mdTypeDef)
#     name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
#     rnameLen = Ref(ULONG(0))
#     rflags = Ref(DWORD(0))
#     rextends = Ref(mdToken(0))
#     res = @ccall $(getVtbl(mdi).GetTypeDefProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         td::mdTypeDef,
#         name::Ref{Cwchar_t},
#         length(name)::ULONG,
#         rnameLen::Ref{ULONG},
#         rflags::Ref{DWORD},
#         rextends::Ref{mdToken}
#         )::HRESULT
#     if res == S_OK
#         return (name=transcode(String, name[begin:rnameLen[]-1]), extends=rextends[], flags=rflags[])
#     end
#     # @show td
#     throw(HRESULT_FAILED(res))
# end

# function fieldValue(jtype::DataType, pval::UVCP_CONSTANT)
#     vt = Ptr{jtype}(pval)
#     return unsafe_load(vt)
# end

# function getFieldProps(mdi::CWMetaDataImport, fd::mdFieldDef)
#     rclass = Ref(mdTypeDef(0))
#     fieldname = Vector{Cwchar_t}(undef, DEFAULT_BUFFER_LEN)
#     rfieldnameLen = Ref(ULONG(0))
#     rattrs = Ref(DWORD(0))
#     rpsigblob = Ref(Ptr{COR_SIGNATURE}(0))
#     rsigbloblen = Ref(ULONG(0))
#     rcplusTypeFlag = Ref(DWORD(0))
#     rvalue = Ref(UVCP_CONSTANT(0))
#     rvalueLen = Ref(ULONG(0))
#     res = @ccall $(getVtbl(mdi).GetFieldProps)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         fd::mdFieldDef,
#         rclass::Ref{mdTypeDef},
#         fieldname::Ref{Cwchar_t},
#         length(fieldname)::ULONG,
#         rfieldnameLen::Ref{ULONG},
#         rattrs::Ref{DWORD},
#         rpsigblob::Ref{Ptr{COR_SIGNATURE}},
#         rsigbloblen::Ref{ULONG},
#         rcplusTypeFlag::Ref{DWORD},
#         rvalue::Ref{UVCP_CONSTANT},
#         rvalueLen::Ref{ULONG}
#         )::HRESULT
#     if res == S_OK
#         name = transcode(String, fieldname[begin:rfieldnameLen[]-1])
#         sigblob = unsafe_wrap(Vector{COR_SIGNATURE}, rpsigblob[], rsigbloblen[])
#         return (name, sigblob, rvalue[], rcplusTypeFlag[])
#     end
    
#     return ("", UInt8[], DWORD(0))
# end

# function enumFields(mdi, rEnum, tok, fields, rcTokens)
#     return @ccall $(getVtbl(mdi).EnumFields)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         rEnum::Ref{HCORENUM}, 
#         tok::mdTypeDef, 
#         fields::Ref{mdFieldDef}, 
#         length(fields)::ULONG, 
#         rcTokens::Ref{ULONG}
#     )::HRESULT
# end

# function closeEnum(mdi, enum)
#     @ccall $(getVtbl(mdi).CloseEnum)(mdi.punk::Ref{COMObject{IMetaDataImport}}, enum::HCORENUM)::Nothing
# end

# function enumFields(mdi::CWMetaDataImport, tok::mdTypeDef)::Vector{mdFieldDef}
#     rEnum = Ref(HCORENUM(0))
#     allfields = mdFieldDef[]
#     fields = zeros(mdFieldDef, DEFAULT_BUFFER_LEN)
#     rcTokens = Ref(ULONG(0))
#     res = enumFields(mdi, rEnum, tok, fields, rcTokens)
#     while res == S_OK
#         append!(allfields, fields[1:rcTokens[]])
#         res = enumFields(mdi, rEnum, tok, fields, rcTokens)
#     end
#     closeEnum(mdi, rEnum[])
#     return allfields
# end

# enumFields(mdi::CWMetaDataImport, typename::String) = enumFields(mdi, findTypeDef(mdi, typename))

# @enum SIG_KIND begin
#     SIG_KIND_DEFAULT = 0x0 
#     SIG_KIND_C = 0x1 
#     SIG_KIND_STDCALL = 0x2 
#     SIG_KIND_THISCALL = 0x3 
#     SIG_KIND_FASTCALL = 0x4 
#     SIG_KIND_VARARG = 0x5 
#     SIG_KIND_FIELD = 0x06 
#     SIG_KIND_HASTHIS = 0x20 
#     SIG_KIND_EXPLICITTHIS = 0x40 
# end

# @enum ELEMENT_TYPE::Byte begin
#     ELEMENT_TYPE_END = 0x00
#     ELEMENT_TYPE_VOID = 0x01
#     ELEMENT_TYPE_BOOLEAN = 0x02
#     ELEMENT_TYPE_CHAR = 0x03
#     ELEMENT_TYPE_I1 = 0x04
#     ELEMENT_TYPE_U1 = 0x05
#     ELEMENT_TYPE_I2 = 0x06
#     ELEMENT_TYPE_U2 = 0x07
#     ELEMENT_TYPE_I4 = 0x08
#     ELEMENT_TYPE_U4 = 0x09
#     ELEMENT_TYPE_I8 = 0x0a
#     ELEMENT_TYPE_U8 = 0x0b
#     ELEMENT_TYPE_R4 = 0x0c
#     ELEMENT_TYPE_R8 = 0x0d
#     ELEMENT_TYPE_STRING = 0x0e
#     ELEMENT_TYPE_PTR = 0x0f # Followed by type
#     ELEMENT_TYPE_BYREF = 0x10 # Followed by type
#     ELEMENT_TYPE_VALUETYPE = 0x11 # Followed by TypeDef or TypeRef token
#     ELEMENT_TYPE_CLASS = 0x12 # Followed by TypeDef or TypeRef token
#     ELEMENT_TYPE_VAR = 0x13 # Generic parameter in a generic type definition, represented as number (compressed unsigned integer)
#     ELEMENT_TYPE_ARRAY = 0x14 # type rank boundsCount bound1 … loCount lo1 …
#     ELEMENT_TYPE_GENERICINST = 0x15 # Generic type instantiation. Followed by type type-arg-count type-1 ... type-n
#     ELEMENT_TYPE_TYPEDBYREF = 0x16
#     ELEMENT_TYPE_I = 0x18 # Size of a native integer, System.IntPtr
#     ELEMENT_TYPE_U = 0x19 # Size of an unsigned native integer. System.UIntPtr
#     # TBD
# end

# # Only handles single dimension array with assumed lower bound of 0
# function decodeArrayBlob(paramblob::Vector{COR_SIGNATURE})
#     ipb = 1
#     type, len = uncompress(paramblob[ipb:end])
#     ipb += len
#     rank, len = uncompress(paramblob[ipb:end])
#     ipb += len
#     @assert rank == 1
#     cbounds, len = uncompress(paramblob[ipb:end])
#     ipb += len
#     @assert cbounds == 1
#     arraylen, len = uncompress(paramblob[ipb:end])
#     return (type, len, arraylen)
# end

# const TYPEATTR_NONE         = 0x00000000
# const TYPEATTR_PTR          = 0x00000001
# const TYPEATTR_VALUETYPE    = 0x00000002
# const TYPEATTR_ARRAY        = 0x00000004

# function paramType(paramblob::Vector{COR_SIGNATURE})
#     len = 1
#     et::ELEMENT_TYPE = ELEMENT_TYPE(paramblob[1])
#     type::mdToken = mdTokenNil
#     typeattr::UInt32 = TYPEATTR_NONE
#     arraylen::Int = 0
    
#     if et == ELEMENT_TYPE_PTR
#         typeattr |= TYPEATTR_PTR
#         subet = ELEMENT_TYPE(paramblob[2])
#         if subet == ELEMENT_TYPE_VALUETYPE
#             typeattr |= TYPEATTR_VALUETYPE
#             type, len = uncompressToken(paramblob[3:end])
#             len += 2
#         else
#             type, len = uncompress(paramblob[2:end])
#             len += 1
#         end
#     elseif et == ELEMENT_TYPE_VALUETYPE
#         typeattr |= TYPEATTR_VALUETYPE
#         type, len = uncompressToken(paramblob[2:end])
#         len += 1
#     elseif et == ELEMENT_TYPE_CLASS
#         type, len = uncompressToken(paramblob[2:end])
#         len += 1
#     elseif et == ELEMENT_TYPE_ARRAY
#         typeattr |= TYPEATTR_ARRAY
#         type, len, arraylen = decodeArrayBlob(paramblob[2:end])
#         len += 1
#     else
#         type = paramblob[1]
#         len = 1
#     end

#     return (type, len, typeattr, arraylen)
# end

# function methodSigblobToTypeInfos(sigblob::Vector{COR_SIGNATURE})
#     sk::SIG_KIND = SIG_KIND(sigblob[1] & 0xF)
#     typeattr = TYPEATTR_NONE
#     paramCount::Int = 0
#     types = Tuple{mdTypeDef, UInt32, Int}[]
#     i = 2

#     # NB Assumes c-api
#     paramCount, len = uncompress(sigblob[i:end])
#     i += len

#     rettype, len, typeattr, arrayLen = paramType(sigblob[i:end])
#     push!(types, (rettype, typeattr, arrayLen))
#     i += len

#     # TODO loop over param count
#     while paramCount > 0 
#         type, len, typeattr, arrayLen = paramType(sigblob[i:end])
#         push!(types, (type, typeattr, arrayLen))
#         i += len
#         paramCount -= 1
#     end

#     return types
# end

# function fieldSigblobToTypeInfo(sigblob::Vector{COR_SIGNATURE})
#     if SIG_KIND(sigblob[1]) == SIG_KIND_FIELD
#         return paramType(sigblob[2:end])
#     end
#     throw("bad signature")
# end

# function enumMembers(mdi::CWMetaDataImport, tok::mdTypeDef)::Vector{mdToken}
#     rEnum = Ref(HCORENUM(0))
#     members = zeros(mdToken, DEFAULT_BUFFER_LEN)
#     rcMembers = Ref(ULONG(0))
#     res = @ccall $(getVtbl(mdi).EnumMembers)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         rEnum::Ref{HCORENUM},
#         tok::mdTypeDef,
#         members::Ref{mdToken},
#         length(members)::ULONG,
#         rcMembers::Ref{ULONG}
#         )::HRESULT
#     if res == S_OK
#         return members[begin:rcMembers[]]
#     end
#     throw(HRESULT_FAILED(res))
# end

# function extends(mdi::CWMetaDataImport, name::String, extends::String)::Bool
#     td = findTypeDef(mdi, name)
#     tdprops = getTypeDefProps(mdi, td)
#     extendsname = getTypeRefName(mdi, tdprops.extends)
#     if extendsname == extends
#         return true
#     end
#     return false
# end

# isStruct(mdi::CWMetaDataImport, name::String) = extends(mdi, name, SYSTEM_VALUETYPE_STR)
# isStruct(mdi::CWMetaDataImport, tr::mdTypeRef) = isString(mdi, getTypeRefName(mdi, tr))
# isCallback(mdi::CWMetaDataImport, name::String) = extends(mdi, name, SYSTEM_MULTICAST_DELEGATE_STR)
# isCallback(mdi::CWMetaDataImport, tr::mdTypeRef) = isCallback(mdi, getTypeRefName(mdi, tr))

# function enumParams(mdi, rEnum, mdtoken, params, rcparams)
#     return @ccall $(getVtbl(mdi).EnumParams)(
#         mdi.punk::Ref{COMObject{IMetaDataImport}}, 
#         rEnum::Ref{HCORENUM}, 
#         mdtoken::mdMethodDef, 
#         params::Ref{mdParamDef}, 
#         length(params)::ULONG, 
#         rcparams::Ref{ULONG}
#     )::HRESULT
# end

# function enumParams(mdi::CWMetaDataImport, mdtoken::mdMethodDef)::Vector{mdParamDef}
#     rEnum = Ref(HCORENUM(0))
#     allparams = mdParamDef[]
#     params = zeros(mdParamDef, DEFAULT_BUFFER_LEN)
#     rcparams = Ref(ULONG(0))
#     res = enumParams(mdi, rEnum, mdtoken, params, rcparams)
#     # @show rcparams[]
#     while res == S_OK
#         append!(allparams, params[1:rcparams[]])
#         res = enumParams(mdi, rEnum, mdtoken, params, rcparams)
#     end
#     closeEnum(mdi, rEnum[])
#     return allparams
# end