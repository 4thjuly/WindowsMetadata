
const DEFAULT_BUFFER_LEN = 1024

const Byte = UInt8

struct GUID
    Data1::Culong
    Data2::Cushort
    Data3::Cushort
    Data4::NTuple{8,Byte}
end

const HRESULT = UInt32
const CLSID = GUID
const IID = GUID

parse_hexbytes(s::String) =  parse(Byte, s, base = 16)

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

# TODO - Make Interface definitions a macro?
struct IMetaDataDispenserVtbl
    QueryInterface::Ptr{Cvoid}
    AddRef::Ptr{Cvoid}
    Release::Ptr{Cvoid}
    DefineScope::Ptr{Cvoid}
    OpenScope::Ptr{Cvoid}
    OpenScopeOnMemmory::Ptr{Cvoid}
end
struct IMetaDataDispenser
    pvtbl::Ptr{IMetaDataDispenserVtbl}
end

rpmdd = Ref(Ptr{IMetaDataDispenser}(C_NULL))
res = @ccall "Rometadata".MetaDataGetDispenser( Ref(CLSID_CorMetaDataDispenser)::Ptr{Cvoid}, 
    Ref(IID_IMetaDataDispenser)::Ptr{Cvoid}, rpmdd::Ptr{Ptr{IMetaDataDispenser}})::HRESULT
@show res
# Test
mdd = unsafe_load(rpmdd[])
vtbl = unsafe_load(mdd.pvtbl)
dump(vtbl)

# TODO Macro to add IUnknown automatically
struct IMetaDataImportVtbl
    QueryInterface::Ptr{Cvoid}
    AddRef::Ptr{Cvoid}
    Release::Ptr{Cvoid}
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

struct IMetaDataImport
    pvtbl::Ptr{IMetaDataImportVtbl}
end

const CorOpenFlags_ofRead = 0x00000000;

rpmdi = Ref(Ptr{IMetaDataImport}(C_NULL)) 
res = @ccall $(vtbl.OpenScope)(
    rpmdd[]::Ref{IMetaDataDispenser}, 
    "Windows.Win32.winmd"::Cwstring, 
    CorOpenFlags_ofRead::Cuint, 
    Ref(IID_IMetaDataImport)::Ptr{Cvoid}, 
    rpmdi::Ref{Ptr{IMetaDataImport}}
    )::HRESULT
@show res
mdi = unsafe_load(rpmdi[])
mdivtbl = unsafe_load(mdi.pvtbl)
dump(mdivtbl)

const ULONG32 = UInt32
const mdToken = ULONG32
const mdTypeDef = mdToken
const mdTokenNil = mdToken(0)
const ULONG = UInt32

rtypetoken = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindTypeDefByName)(
    rpmdi[]::Ptr{IMetaDataImport}, 
    "Windows.Win32.WindowsAndMessaging.Apis"::Cwstring, 
    mdTokenNil::mdToken, 
    rtypetoken::Ref{mdToken}
    )::HRESULT
@show res
dump(rtypetoken[])

rmethodDef = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindMethod)(
    rpmdi[]::Ptr{IMetaDataImport}, 
    rtypetoken[]::mdToken, 
    "RegisterClassExW"::Cwstring, 
    C_NULL::Ref{Cvoid}, 
    0::ULONG, 
    rmethodDef::Ref{mdToken}
    )::HRESULT 
@show res
dump(rmethodDef[])

const mdMethodDef = mdToken
const DWORD = UInt32
const mdModuleRef = mdToken

rflags = Ref(DWORD(0))
importname = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rnameLen = Ref(ULONG(0))
rmoduleRef = Ref(mdModuleRef(0))
res = @ccall $(mdivtbl.GetPinvokeMap)(
    rpmdi[]::Ptr{IMetaDataImport}, 
    rmethodDef[]::mdMethodDef, 
    rflags::Ref{DWORD},
    importname::Ref{Cwchar_t},
    length(importname)::ULONG, 
    rnameLen::Ref{ULONG}, 
    rmoduleRef::Ref{mdModuleRef}
    )::HRESULT
@show res
@show rflags[]
@show rnameLen[]
println("API: ", transcode(String, importname[begin:rnameLen[]-1]))

modulename = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rmodulanameLen = Ref(ULONG(0))
res = @ccall $(mdivtbl.GetModuleRefProps)(
    rpmdi[]::Ptr{IMetaDataImport}, 
    rmoduleRef[]::mdModuleRef,
    modulename::Ref{Cwchar_t},
    length(modulename)::ULONG,
    rmodulanameLen::Ref{ULONG}
    )::HRESULT
@show res
println("Module: ", transcode(String, modulename[begin:rmodulanameLen[]-1]))

const mdParamDef = mdToken

rparamDef = Ref(mdParamDef(0))
res = @ccall $(mdivtbl.GetParamForMethodIndex)(
    rpmdi[]::Ptr{IMetaDataImport},
    rmethodDef[]::mdMethodDef,
    1::ULONG,
    rparamDef::Ref{mdParamDef}
)::HRESULT
@show res
@show rparamDef[]

paramName = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rparamMethodDef = Ref(mdMethodDef(0))
rparamNameLen = Ref(ULONG(0))
rseq = Ref(ULONG(0))
rattr = Ref(DWORD(0))
rcplustypeFlag = Ref(DWORD(0))
rpvalue = Ptr{Cvoid}(0)
rcchValue = Ref(ULONG(0))
res = @ccall $(mdivtbl.GetParamProps)(
    rpmdi[]::Ptr{IMetaDataImport},
    rparamDef[]::mdParamDef,
    rparamMethodDef::Ref{mdMethodDef},
    rseq::Ref{ULONG},
    paramName::Ref{Cwchar_t},
    length(paramName)::ULONG,
    rparamNameLen::Ptr{ULONG},
    rattr::Ptr{DWORD},
    rcplustypeFlag::Ptr{DWORD},
    rpvalue::Ptr{Cvoid},
    rcchValue::Ptr{ULONG}
    )::HRESULT
@show res
@show rparamMethodDef[]
@show rseq[]
@show rparamNameLen[]
println("Param: ", transcode(String, paramName[begin:rparamNameLen[]-1]))

const mdSignature = mdToken
const COR_SIGNATURE = UInt8

# rpsig = Ref(Ptr{COR_SIGNATURE}(C_NULL))
# rsigLen = Ref(ULONG(0))
# res = @ccall $(mdivtbl.GetSigFromToken)(
#     rpmdi[]::Ptr{IMetaDataImport},
#     rmethodDef[]::mdSignature,
#     rpsig::Ref{Ptr{COR_SIGNATURE}},
#     rsigLen::Ref{ULONG}
#     )::HRESULT
# @show res

rclass = Ref(mdTypeDef(0))
methodName = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rmethodNameLen = Ref(ULONG(0))
rattr = Ref(DWORD(0))
rpsig = Ref(Ptr{COR_SIGNATURE}(C_NULL))
rsigLen = Ref(ULONG(0))
rrva = Ref(ULONG(0))
rflags = Ref(DWORD(0))
res = @ccall $(mdivtbl.GetMethodProps)(
    rpmdi[]::Ptr{IMetaDataImport},
    rmethodDef[]::mdMethodDef,
    rclass::Ref{mdTypeDef},
    methodName::Ref{Cwchar_t},
    length(methodName)::ULONG,
    rmethodNameLen::Ref{ULONG},
    rattr::Ref{DWORD},
    rpsig::Ref{Ptr{COR_SIGNATURE}},
    rsigLen::Ref{ULONG},
    rrva::Ref{ULONG},
    rflags::Ref{DWORD}
    )::HRESULT
@show res
@show rclass[]
@show rmethodNameLen[]
println("methodName: ", transcode(String, methodName[begin:rmethodNameLen[]-1]))
@show rsigLen[]
sig = unsafe_wrap(Vector{UInt8}, Ptr{UInt8}(rpsig[]), rsigLen[])
@show sig
println()

const mdTypeRef = mdToken
const TYPEDEF_TYPE_FLAG = 0x02000000
const TYPEREF_TYPE_FLAG = 0x01000000

encoded = UInt32(sig[6] & 0x3F) << 8 | UInt32(sig[7])
@show encoded
refDefOrSpec = encoded & 0x03
@show refDefOrSpec
# assume ref
typedref = mdTypeRef(TYPEREF_TYPE_FLAG | (encoded >> 2))
@show typedref
println()

# check
valid = @ccall $(mdivtbl.IsValidToken)(
    rpmdi[]::Ptr{IMetaDataImport},
    typedref::mdToken
    )::Bool
@show valid
println()

rscope = Ref(mdToken(0))
name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rnameLen = Ref(ULONG(0))
res = @ccall $(mdivtbl.GetTypeRefProps)(
    rpmdi[]::Ptr{IMetaDataImport},
    typedref::mdTypeRef,
    rscope::Ref{mdToken},
    name::Ref{Cwchar_t},
    length(name)::ULONG,
    rnameLen::Ref{ULONG}
    )::HRESULT
@show res
@show rscope[]
@show rnameLen[]
println("refname: ", transcode(String, name[begin:rnameLen[]-1]))
println()

# typename = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
# rtypenameLen = Ref(ULONG(0))
# rflags = Ref(DWORD(0))
# rExtends = Ref(mdToken(0))
# res = @ccall $(mdivtbl.GetTypeDefProps)(
#     rpmdi[]::Ptr{IMetaDataImport},
#     typedref::mdTypeRef,
#     typename::Ref{Cwchar_t},
#     length(typename)::ULONG,
#     rtypenameLen::Ref{ULONG},
#     rExtends::Ref{mdToken}
#     )::HRESULT
# @show res
# @show rflags[]
# @show rExtends[]
# @show rtypenameLen[]
# println("defname: ", transcode(String, typename[begin:rtypenameLen[]-1]))
# println()

# rscope = Ref(mdToken(0))
# name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
# rnameLen = Ref(ULONG(0))
# res = @ccall $(mdivtbl.GetTypeRefProps)(
#     rpmdi[]::Ptr{IMetaDataImport},
#     rExtends[]::mdTypeRef,
#     rscope::Ref{mdToken},
#     name::Ref{Cwchar_t},
#     length(name)::ULONG,
#     rnameLen::Ref{ULONG}
#     )::HRESULT
# @show res
# @show rnameLen[]
# println("name: ", transcode(String, name[begin:rnameLen[]-1]))
# println()

# name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
# rameLen = Ref(ULONG(0))
# rflags = Ref(DWORD(0))
# res = @ccall $(mdivtbl.GetTypeDefProps)(
#     rpmdi[]::Ptr{IMetaDataImport},
#     rExtends[]::mdTypeRef,
#     typename::Ref{Cwchar_t},
#     length(typename)::ULONG,
#     rtypenameLen::Ref{ULONG},
#     rExtends::Ref{mdToken}
#     )::HRESULT
# @show res
# @show rflags[]
# @show rExtends[]
# @show rtypenameLen[]
# println("typename: ", transcode(String, typename[begin:rtypenameLen[]-1]))
# println()