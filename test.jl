# typedef struct {
#     unsigned long  Data1;
#     unsigned short Data2;
#     unsigned short Data3;
#     byte           Data4[ 8 ];
# } GUID;
# HRESULT MetaDataGetDispenser(
#   REFCLSID rclsid,
#   REFIID   riid,
#   LPVOID   *ppv
# );

# IMetadataDispsener dispener;
# MetaDataGetDispenser(CLSID_CorMetaDataDispenser, IMetaDataDispenser, out dispenser);

# interface IUnknown {
#   virtual HRESULT QueryInterface (REFIID riid, void **ppvObject) = 0;
#   virtual ULONG   AddRef () = 0;
#   virtual ULONG   Release () = 0;
# };

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

macro guid_str(s)
    GUID(
        parse(Culong, s[1:8], base = 16), 
        parse(Cushort, s[10:13], base = 16), 
        parse(Cushort, s[15:18], base = 16), 
        (
            parse(Byte, s[20:21], base = 16), 
            parse(Byte, s[22:23], base = 16), 
            parse(Byte, s[25:26], base = 16), 
            parse(Byte, s[27:28], base = 16), 
            parse(Byte, s[29:30], base = 16), 
            parse(Byte, s[31:32], base = 16), 
            parse(Byte, s[33:34], base = 16), 
            parse(Byte, s[35:36], base = 16)
        )
    )
end

const CLSID_CorMetaDataDispenser = guid"E5CB7A31-7512-11d2-89CE-0080C792E5D8"
const IID_IMetaDataDispenser = guid"809C652E-7396-11D2-9771-00A0C9B4D50C"

# TODO - Make Interface definitions a macro?
struct IMetaDataDispenserVtbl
    QueryInterface::Ptr{Cvoid}
    AddRef::Ptr{Cvoid}
    Release::Ptr{Cvoid}
    DefineScope::Ptr{Cvoid}
    OpenScope::Ptr{Cvoid}
    OpenScopeOnMemmory::Ptr{Cvoid}
    # IMetaDataDispenserVtbl() = new(C_NULL, C_NULL, C_NULL, C_NULL, C_NULL, C_NULL)
end
struct IMetaDataDispenser
    pvtbl::Ptr{IMetaDataDispenserVtbl}
    # IMetaDataDispenser() = new(Ptr{IMetaDataDispenserVtbl}(C_NULL))
end

rpmdd = Ref(Ptr{IMetaDataDispenser}(C_NULL))
res = @ccall "Rometadata".MetaDataGetDispenser(
    Ref(CLSID_CorMetaDataDispenser)::Ptr{Cvoid}, 
    Ref(IID_IMetaDataDispenser)::Ptr{Cvoid}, 
    rpmdd::Ptr{Ptr{IMetaDataDispenser}}
    )::Cuint

# Test
mdd = unsafe_load(rpmdd[])
vtbl = unsafe_load(mdd.pvtbl)
