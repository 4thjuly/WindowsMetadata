
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

macro guid_str(s)
    GUID(parse(Culong, s[1:8], base = 16), 
        parse(Cushort, s[10:13], base = 16), 
        parse(Cushort, s[15:18], base = 16), 
        (parse_hexbytes(s[20:21]), 
            parse_hexbytes(s[22:23]), 
            parse_hexbytes(s[25:26]), 
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
res = @ccall "Rometadata".MetaDataGetDispenser(
    Ref(CLSID_CorMetaDataDispenser)::Ptr{Cvoid}, 
    Ref(IID_IMetaDataDispenser)::Ptr{Cvoid}, 
    rpmdd::Ptr{Ptr{IMetaDataDispenser}})::HRESULT

# Test
mdd = unsafe_load(rpmdd[])
vtbl = unsafe_load(mdd.pvtbl)
dump(vtbl)






struct IMetaDataImportVtbl
    CloseEnum::Ptr{Cvoid}
    CountEnum::Ptr{Cvoid}
    EnumCustomAttributes::Ptr{Cvoid}
    EnumEvents::Ptr{Cvoid}
    EnumFields::Ptr{Cvoid}
    EnumFieldsWithName::Ptr{Cvoid}
    EnumInterfaceImpls::Ptr{Cvoid}
    EnumMemberRefs::Ptr{Cvoid}
    EnumMembers::Ptr{Cvoid}
    EnumMembersWithName::Ptr{Cvoid}
    EnumMethodImpls::Ptr{Cvoid}
    EnumMethods::Ptr{Cvoid}
    EnumMethodSemantics::Ptr{Cvoid}
    EnumMethodsWithName::Ptr{Cvoid}
    EnumModuleRefs::Ptr{Cvoid}
    EnumParams::Ptr{Cvoid}
    EnumPermissionSets::Ptr{Cvoid}
    EnumProperties::Ptr{Cvoid}
    EnumSignatures::Ptr{Cvoid}
    EnumTypeDefs::Ptr{Cvoid}
    EnumTypeRefs::Ptr{Cvoid}
    EnumTypeSpecs::Ptr{Cvoid}
    EnumUnresolvedMethods::Ptr{Cvoid}
    EnumUserStrings::Ptr{Cvoid}
    FindField::Ptr{Cvoid}
    FindMember::Ptr{Cvoid}
    FindMemberRef::Ptr{Cvoid}
    FindMethod::Ptr{Cvoid}
    FindTypeDefByName::Ptr{Cvoid}
    FindTypeRef::Ptr{Cvoid}
    GetClassLayout::Ptr{Cvoid}
    GetCustomAttributeByName::Ptr{Cvoid}
    GetCustomAttributeProps::Ptr{Cvoid}
    GetEventProps::Ptr{Cvoid}
    GetFieldMarshal::Ptr{Cvoid}
    GetFieldProps::Ptr{Cvoid}
    GetInterfaceImplProps::Ptr{Cvoid}
    GetMemberProps::Ptr{Cvoid}
    GetMemberRefProps::Ptr{Cvoid}
    GetMethodProps::Ptr{Cvoid}
    GetMethodSemantics::Ptr{Cvoid}
    GetModuleFromScope::Ptr{Cvoid}
    GetModuleRefProps::Ptr{Cvoid}
    GetNameFromToken::Ptr{Cvoid}
    GetNativeCallConvFromSig::Ptr{Cvoid}
    GetNestedClassProps::Ptr{Cvoid}
    GetParamForMethodIndex::Ptr{Cvoid}
    GetParamProps::Ptr{Cvoid}
    GetPermissionSetProps::Ptr{Cvoid}
    GetPinvokeMap::Ptr{Cvoid}
    GetPropertyProps::Ptr{Cvoid}
    GetRVA::Ptr{Cvoid}
    GetScopeProps::Ptr{Cvoid}
    GetSigFromToken::Ptr{Cvoid}
    GetTypeDefProps::Ptr{Cvoid}
    GetTypeRefProps::Ptr{Cvoid}
    GetTypeSpecFromToken::Ptr{Cvoid}
    GetUserString::Ptr{Cvoid}
    IsGlobal::Ptr{Cvoid}
    IsValidToken::Ptr{Cvoid}
    ResetEnum::Ptr{Cvoid}
    ResolveTypeRef::Ptr{Cvoid}
end
struct IMetaDataImport
    pvtbl::Ptr{IMetaDataImportVtbl}
end

const CorOpenFlags_ofRead = 0x00000000;

# Can't use @ccall
rmdi = Ref(Ptr{IMetaDataImport}(C_NULL)) 
res = ccall(vtbl.OpenScope, HRESULT, (Ptr{IMetaDataDispenser}, Cwstring, Cuint, Ptr{Cvoid}, Ptr{Ptr{IMetaDataImport}}), 
    rpmdd[], "Windows.Win32.winmd", CorOpenFlags_ofRead, Ref(IID_IMetaDataImport), rmdi)
mdi = unsafe_load(rmdi[])
mtdi_vtbl = unsafe_load(mdi.pvtbl)
dump(mtdi_vtbl)

