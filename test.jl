
# DECLARE_INTERFACE_(IMetaDataDispenser, IUnknown)
# {
#     STDMETHOD(DefineScope)(                 // Return code.
#         REFCLSID    rclsid,                 // [in] What version to create.
#         DWORD       dwCreateFlags,          // [in] Flags on the create.
#         REFIID      riid,                   // [in] The interface desired.
#         IUnknown    **ppIUnk) PURE;         // [out] Return interface on success.

#     STDMETHOD(OpenScope)(                   // Return code.
#         LPCWSTR     szScope,                // [in] The scope to open.
#         DWORD       dwOpenFlags,            // [in] Open mode flags.
#         REFIID      riid,                   // [in] The interface desired.
#         IUnknown    **ppIUnk) PURE;         // [out] Return interface on success.

#     STDMETHOD(OpenScopeOnMemory)(           // Return code.
#         LPCVOID     pData,                  // [in] Location of scope data.
#         ULONG       cbData,                 // [in] Size of the data pointed to by pData.
#         DWORD       dwOpenFlags,            // [in] Open mode flags.
#         REFIID      riid,                   // [in] The interface desired.
#         IUnknown    **ppIUnk) PURE;         // [out] Return interface on success.
# };

# //Open the winmd file we want to dump
# String filename = "C:\Windows\System32\WinMetadata\Windows.Globalization.winmd";

# IMetaDataImport reader; //IMetadataImport2 supports generics
# dispenser.OpenScope(filename, ofRead, IMetaDataImport, out reader); //"Import" is used to read metadata. "Emit" is used to write metadata.

# const Byte = UInt8
# Pointer enum = null;
# mdTypeDef typeID;
# Int32 nRead;
# while (reader.EnumTypeDefs(enum, out typeID, 1, out nRead) = S_OK)
# {
#    ProcessToken(reader, typeID);
# }
# reader.CloseEnum(enum);

# void ProcessToken(IMetaDataImport reader, mdTypeDef typeID)
# {
#    //Get three interesting properties of the token:
#    String      typeName;       //e.g. "Windows.Globalization.NumberFormatting.DecimalFormatter"
#    UInt32      ancestorTypeID; //the token of this type's ancestor (e.g. Object, Interface, System.ValueType, System.Enum)
#    CorTypeAttr flags;          //various flags about the type (e.g. public, private, is an interface)

#    GetTypeInfo(reader, typeID, out typeName, out ancestorTypeID, out flags);
# }


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

rmdi = Ref(Ptr{IMetaDataImport}(C_NULL)) 
res = @ccall $(vtbl.OpenScope)(rpmdd[]::Ptr{IMetaDataDispenser}, "Windows.Win32.winmd"::Cwstring, 
    CorOpenFlags_ofRead::Cuint, Ref(IID_IMetaDataImport)::Ptr{Cvoid}, rmdi::Ptr{Ptr{IMetaDataImport}})::HRESULT
@show res
mdi = unsafe_load(rmdi[])
mdivtbl = unsafe_load(mdi.pvtbl)
dump(mdivtbl)

const ULONG32 = UInt32
const mdToken = ULONG32
const mdTypeDef = mdToken
const mdTokenNil = mdToken(0)
const ULONG = UInt32

rtypetoken = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindTypeDefByName)(rmdi[]::Ptr{IMetaDataImport}, "Windows.Win32.WindowsAndMessaging.Apis"::Cwstring, 
    mdTokenNil::mdToken, rtypetoken::Ptr{mdToken})::HRESULT
@show res
dump(rtypetoken[])

methodDef = Ref(mdToken(0))
res = @ccall $(mdivtbl.FindMethod)(rmdi[]::Ptr{IMetaDataImport}, rtypetoken[]::mdToken, "GetDesktopWindow"::Cwstring, 
    C_NULL::Ptr{Cvoid}, 0::ULONG, rmethodDef::Ptr{mdToken})::HRESULT 
@show res
dump(rmethodDef[])

const mdMethodDef = mdToken
const DWORD = UInt32
const mdModuleRef = mdToken

rflags = Ref(DWORD(0))
importname = zeros(Cwchar_t, 1024)
rnameLen = Ref(ULONG(0))
rmoduleRef = Ref(mdModuleRef(0))
res = @ccall $(mdivtbl.GetPinvokeMap)(
    rmdi[]::Ptr{IMetaDataImport}, 
    rmethodDef[]::mdMethodDef, 
    rflags::Ptr{DWORD},
    importname::Ptr{Cwchar_t},
    length(importname)::ULONG, 
    rnameLen::Ptr{ULONG}, 
    rmoduleRef::Ptr{mdModuleRef}
    )::HRESULT
@show res
@show rflags[]
@show rnameLen[]
println("API: ", transcode(String, importname[begin:rnameLen[]-1]))

modulename = zeros(Cwchar_t, 1024)
rmodulanameLen = Ref(ULONG(0))
res = @ccall $(mdivtbl.GetModuleRefProps)(
    rmdi[]::Ptr{IMetaDataImport}, 
    rmoduleRef[]::mdModuleRef,
    modulename::Ptr{Cwchar_t},
    length(modulename)::ULONG,
    rmodulanameLen::Ptr{ULONG}
    )::HRESULT
@show res
println("Module: ", transcode(String, modulename[begin:rmodulanameLen[]-1]))
