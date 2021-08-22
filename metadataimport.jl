import Base.@kwdef

const DEFAULT_BUFFER_LEN = 1024

const Byte = UInt8

struct GUID
    Data1::Culong
    Data2::Cushort
    Data3::Cushort
    Data4::NTuple{8,Byte}
end

const HRESULT = UInt32
const S_OK = 0x00000000
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

struct IUnknown
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
    iUnknown::IUnknown
    DefineScope::Ptr{Cvoid}
    OpenScope::Ptr{Cvoid}
    OpenScopeOnMemmory::Ptr{Cvoid}
end

struct IMetaDataDispenser
    pvtbl::Ptr{IMetaDataDispenserVtbl}
end

# struct COMObject{T}
#     pvtbl::Ptr{T}
# end

struct COMWrapper{T1, T2}
    punk::Ptr{T1}
    vtbl::T2
end

function metadataDispenser()
    rpmdd = Ref(Ptr{IMetaDataDispenser}(C_NULL))
    res = @ccall "Rometadata".MetaDataGetDispenser( 
        Ref(CLSID_CorMetaDataDispenser)::Ptr{Cvoid}, 
        Ref(IID_IMetaDataDispenser)::Ptr{Cvoid}, 
        rpmdd::Ref{Ptr{IMetaDataDispenser}}
        )::HRESULT
    if res == S_OK
        pmdd = rpmdd[]
        mdd = unsafe_load(pmdd)
        vtbl = unsafe_load(mdd.pvtbl)
        return COMWrapper{IMetaDataDispenser, IMetaDataDispenserVtbl}(pmdd, vtbl)
    end
    throw(DomainError(res))
end

mdd = metadataDispenser()

struct IMetaDataImportVtbl
    iUnknown::IUnknown
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
res = @ccall $(mdd.vtbl.OpenScope)(
    mdd.punk::Ref{IMetaDataDispenser}, 
    "Windows.Win32.winmd"::Cwstring,
    CorOpenFlags_ofRead::Cuint, 
    Ref(IID_IMetaDataImport)::Ptr{Cvoid}, 
    rpmdi::Ref{Ptr{IMetaDataImport}}
    )::HRESULT
@show res
pmdi = rpmdi[]
mdi = unsafe_load(pmdi)
mdivtbl = unsafe_load(mdi.pvtbl)

const ULONG32 = UInt32
const mdToken = ULONG32
const mdTypeDef = mdToken
const mdTokenNil = mdToken(0)
const ULONG = UInt32

rtypetoken = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindTypeDefByName)(
    pmdi::Ptr{IMetaDataImport}, 
    "Windows.Win32.WindowsAndMessaging.Apis"::Cwstring, 
    mdTokenNil::mdToken, 
    rtypetoken::Ref{mdToken}
    )::HRESULT
@show res
dump(rtypetoken[])

rmethodDef = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindMethod)(
    pmdi::Ptr{IMetaDataImport}, 
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
    pmdi::Ptr{IMetaDataImport}, 
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
    pmdi::Ptr{IMetaDataImport}, 
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
    pmdi::Ptr{IMetaDataImport},
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
    pmdi::Ptr{IMetaDataImport},
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

rclass = Ref(mdTypeDef(0))
methodName = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
rmethodNameLen = Ref(ULONG(0))
rattr = Ref(DWORD(0))
rpsig = Ref(Ptr{COR_SIGNATURE}(C_NULL))
rsigLen = Ref(ULONG(0))
rrva = Ref(ULONG(0))
rflags = Ref(DWORD(0))
res = @ccall $(mdivtbl.GetMethodProps)(
    pmdi::Ptr{IMetaDataImport},
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
sig = unsafe_wrap(Vector{COR_SIGNATURE}, Ptr{UInt8}(rpsig[]), rsigLen[])
@show sig
println()

const mdTypeRef = mdToken
const mdTypeSpec = mdToken

const TYPEREF_TYPE_FLAG = 0x01000000
const TYPEDEF_TYPE_FLAG = 0x02000000
const FIELDDEF_TYPE_FLAG = 0x04000000;
const TYPESPEC_TYPE_FLAG = 0x1b000000

function uncompressSig(sig::AbstractVector{COR_SIGNATURE})::Union{mdTypeRef, mdTypeDef, mdTypeSpec}
    ctok::UInt32 = UInt32(0)
    if sig[1] & 0x80 == 0x00
        ctok = UInt32(sig[1])
    elseif sig[1] & 0xC0 == 0x80
        ctok = UInt32(sig[1] & 0x3F) << 8 | UInt32(sig[2])
    elseif sig[1] & 0xE0 == 0xC0
        ctok = UInt32(sig[1] & 0x1f) << 24 | UInt32(sig[2]) << 16 | UInt32(sig[3]) << 8 | UInt32(sig[4])
    else
        error("Bad signature")
    end
    if ctok & 0x03 == 0x00
        return mdTypeDef(TYPEDEF_TYPE_FLAG | (ctok >> 2))
    elseif ctok & 0x03 == 0x01
        return mdTypeRef(TYPEREF_TYPE_FLAG | (ctok >> 2))
    elseif ctok & 0x03 == 0x02
        return mdTypeDef(TYPESPEC_TYPE_FLAG | (ctok >> 2))
    end
    return 0
end

typedref = uncompressSig(@view sig[6:7])
@show typedref

# check
valid = @ccall $(mdivtbl.IsValidToken)(
    pmdi::Ptr{IMetaDataImport},
    typedref::mdToken
    )::Bool
@show valid

function getTypeRefName(tr::mdTypeRef)::String
    rscope = Ref(mdToken(0))
    name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
    rnameLen = Ref(ULONG(0))
    res = @ccall $(mdivtbl.GetTypeRefProps)(
        pmdi::Ptr{IMetaDataImport},
        tr::mdTypeRef,
        rscope::Ref{mdToken},
        name::Ref{Cwchar_t},
        length(name)::ULONG,
        rnameLen::Ref{ULONG}
        )::HRESULT
    if res == S_OK
        return transcode(String, name[begin:rnameLen[]-1])
    end
    return ""
end

function getName(mdt::mdToken)
    if mdt & TYPEDEF_TYPE_FLAG == TYPEDEF_TYPE_FLAG
        return getTypeDefName(mdt)
    elseif mdt & TYPEREF_TYPE_FLAG == TYPEREF_TYPE_FLAG
        return getTypeRefName(mdt)
    else
        return ""
    end
end

structname = getTypeRefName(typedref)
@show structname
println()

function findTypeDef(name::String)::mdToken
    rStructToken = Ref(mdToken(0))
    res = @ccall $(mdivtbl.FindTypeDefByName)(
        pmdi::Ptr{IMetaDataImport}, 
        name::Cwstring, 
        mdTokenNil::mdToken, 
        rStructToken::Ref{mdToken}
        )::HRESULT
    if res == S_OK
        return rStructToken[]
    end
    return mdTokenNil
end

structToken = findTypeDef(structname)
@show structToken
println()

function getTypeDefName(td::mdTypeDef)::String
    name = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
    rnameLen = Ref(ULONG(0))
    rflags = Ref(DWORD(0))
    rextends = Ref(mdToken(0))
    res = @ccall $(mdivtbl.GetTypeDefProps)(
        pmdi::Ptr{IMetaDataImport},
        td::mdTypeRef,
        name::Ref{Cwchar_t},
        length(name)::ULONG,
        rnameLen::Ref{ULONG},
        rflags::Ref{DWORD},
        rextends::Ref{mdToken}
        )::HRESULT
    return res == S_OK ? transcode(String, name[begin:rnameLen[]-1]) : ""
end

const mdFieldDef = mdToken
const UVCP_CONSTANT = Ptr{Cvoid}

function fieldProps(fd::mdFieldDef)
    rclass = Ref(mdTypeDef(0))
    fieldname = zeros(Cwchar_t, DEFAULT_BUFFER_LEN)
    rfieldnameLen = Ref(ULONG(0))
    rattrs = Ref(DWORD(0))
    rpsigblob = Ref(Ptr{COR_SIGNATURE}(0))
    rsigbloblen = Ref(ULONG(0))
    rcplusTypeFlag = Ref(DWORD(0))
    rvalue = Ref(UVCP_CONSTANT(0))
    rvalueLen = Ref(ULONG(0))
    res = @ccall $(mdivtbl.GetFieldProps)(
        pmdi::Ptr{IMetaDataImport},
        fd::mdFieldDef,
        rclass::Ref{mdTypeDef},
        fieldname::Ref{Cwchar_t},
        length(fieldname)::ULONG,
        rfieldnameLen::Ref{ULONG},
        rattrs::Ref{DWORD},
        rpsigblob::Ref{Ptr{COR_SIGNATURE}},
        rsigbloblen::Ref{ULONG},
        rcplusTypeFlag::Ref{DWORD},
        rvalue::Ref{UVCP_CONSTANT},
        rvalueLen::Ref{ULONG}
        )::HRESULT
    if res == S_OK
        name = transcode(String, fieldname[begin:rfieldnameLen[]-1])
        sigblob = unsafe_wrap(Vector{COR_SIGNATURE}, rpsigblob[], rsigbloblen[])
        return (name=name, sigblob=sigblob, cptype=rcplusTypeFlag[])
    end
    
    return ("", UInt8[], DWORD(0))
end

const HCORENUM = Ptr{Cvoid}

function enumFields(tok::mdTypeDef)::Vector{mdFieldDef}
    rEnum = Ref(HCORENUM(0))
    fields = zeros(mdFieldDef, DEFAULT_BUFFER_LEN)
    rcTokens = Ref(ULONG(0))
    res = @ccall $(mdivtbl.EnumFields)(
        pmdi::Ptr{IMetaDataImport}, 
        rEnum::Ref{HCORENUM},
        tok::mdTypeDef,
        fields::Ref{mdFieldDef},
        length(fields)::ULONG,
        rcTokens::Ref{ULONG}
        )::HRESULT
    if res == S_OK
        return fields[begin:rcTokens[]]
    end
    return nothing
end

fields = enumFields(structToken)

@enum SIG_KIND begin
   SIG_KIND_FIELD = 0x06 
end

@enum ELEMENT_TYPE::Byte begin
    ELEMENT_TYPE_END = 0x00
    ELEMENT_TYPE_VOID = 0x01
    ELEMENT_TYPE_BOOLEAN = 0x02
    ELEMENT_TYPE_CHAR = 0x03
    ELEMENT_TYPE_I1 = 0x04
    ELEMENT_TYPE_U1 = 0x05
    ELEMENT_TYPE_I2 = 0x06
    ELEMENT_TYPE_U2 = 0x07
    ELEMENT_TYPE_I4 = 0x08
    ELEMENT_TYPE_U4 = 0x09
    ELEMENT_TYPE_I8 = 0x0a
    ELEMENT_TYPE_U8 = 0x0b
    ELEMENT_TYPE_R4 = 0x0c
    ELEMENT_TYPE_R8 = 0x0d
    ELEMENT_TYPE_STRING = 0x0e
    ELEMENT_TYPE_PTR = 0x0f # Followed by type
    ELEMENT_TYPE_BYREF = 0x10 # Followed by type
    ELEMENT_TYPE_VALUETYPE = 0x11 # Followed by TypeDef or TypeRef token
    ELEMENT_TYPE_CLASS = 0x12 # Followed by TypeDef or TypeRef token
    ELEMENT_TYPE_VAR = 0x13 # Generic parameter in a generic type definition, represented as number (compressed unsigned integer)
    ELEMENT_TYPE_ARRAY = 0x14 # type rank boundsCount bound1 … loCount lo1 …
    ELEMENT_TYPE_GENERICINST = 0x15 # Generic type instantiation. Followed by type type-arg-count type-1 ... type-n
    ELEMENT_TYPE_TYPEDBYREF = 0x16
    ELEMENT_TYPE_I = 0x18 # System.IntPtr
    # TBD
end

function sigblobtoTypeInfo(sigblob::Vector{COR_SIGNATURE})
    sk::SIG_KIND = SIG_KIND(sigblob[1])
    et::ELEMENT_TYPE = ELEMENT_TYPE_VOID
    subtype::Union{ELEMENT_TYPE, mdToken} = ELEMENT_TYPE_VOID

    if sk == SIG_KIND_FIELD
        et = ELEMENT_TYPE(sigblob[2])
        if et == ELEMENT_TYPE_PTR
            subtype = ELEMENT_TYPE(sigblob[3])
        elseif et == ELEMENT_TYPE_VALUETYPE
            subtype = mdToken(uncompressSig(sigblob[3:end]))
        elseif et == ELEMENT_TYPE_CLASS
            subtype = mdToken(uncompressSig(sigblob[3:end]))
        end
    end

    return (sigkind=sk, elementtype=et, subtype=subtype)
end

function showFields(fields::Vector{mdFieldDef})
    for field in fields
        fp = fieldProps(field)
        @show fp.name
        @show fp.sigblob
        @show sigblobtoTypeInfo(fp.sigblob)
    end
end

showFields(fields)
println()

# drill in to last field
name = ((fields[end] |> fieldProps).sigblob |> sigblobtoTypeInfo).subtype |> getName
@show name
name |> findTypeDef |> enumFields |> showFields
