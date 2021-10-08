include("winmd.jl")
import Base.unsafe_convert

const FALSE = Int(false)
const TRUE = Int(1)
macro L_str(s) transcode(Cwchar_t, s) end
RGB(r::UInt8, g::UInt8, b::UInt8)::UInt32 = (UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b))

winmd = Winmd("Windows.Win32")

convertTypeToJulia(winmd, "Gdi.PAINTSTRUCT")
convertTypeToJulia(winmd, "DisplayDevices.RECT")
convertTypeToJulia(winmd, "WindowsAndMessaging.WNDCLASSEXW")
convertTypeToJulia(winmd, "WindowsAndMessaging.MSG")

const WSS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WS_(?!._))", "WS")
const CSS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CS_(?!._))", "CS")
const CWS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CW_(?!._))", "CW")
const IDIS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDI_(?!._))", "IDI")
const IDCS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDC_(?!._))", "IDC")
const WMS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WM_(?!._))", "WM")
const COLORS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(COLOR_(?!._))", "COLOR")

macro wndproc(wp) return :(@cfunction($wp, SystemServices_LRESULT, (WindowsAndMessaging_HWND, UInt32, WindowsAndMessaging_WPARAM, WindowsAndMessaging_LPARAM))) end

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "PostQuitMessage")
convertFunctionToJulia(winmd, "Gdi.Apis", "BeginPaint")
convertFunctionToJulia(winmd, "Gdi.Apis", "CreateSolidBrush")
convertFunctionToJulia(winmd, "Gdi.Apis", "FillRect")
convertFunctionToJulia(winmd, "Gdi.Apis", "DeleteObject")
convertFunctionToJulia(winmd, "Gdi.Apis", "EndPaint")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "DefWindowProcW")


const Gdi32 = "Gdi32" 
const User32 = "User32" 

const PVOID = Ptr{Cvoid}
const HANDLE = PVOID
const HDC = HANDLE
const HWND = HANDLE
const BOOL = Cint
const COLORREF = DWORD
const BYTE = Cuchar
const LONG = Clong
const HGDIOBJ = HANDLE
const HBRUSH = HANDLE

struct tagRECT
    left::LONG
    top::LONG
    right::LONG
    bottom::LONG
end
const RECT = tagRECT

struct tagPAINTSTRUCT
    hdc::HDC
    fErase::BOOL
    rcPaint::RECT
    fRestore::BOOL
    fIncUpdate::BOOL
    rgbReserved::NTuple{32, BYTE}
end
const PAINTSTRUCT = tagPAINTSTRUCT
const LPPAINTSTRUCT = Ptr{tagPAINTSTRUCT}

_BeginPaint(hWnd::HWND, lpPaint::LPPAINTSTRUCT) = ccall((:BeginPaint, User32), HDC, (HWND, LPPAINTSTRUCT), hWnd, lpPaint)
_EndPaint(hWnd::HWND, lpPaint) =  ccall((:EndPaint, User32), BOOL, (HWND, Ptr{PAINTSTRUCT}), hWnd, lpPaint)
_RGB(r::BYTE, g::BYTE, b::BYTE)::COLORREF = (UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b))
_DeleteObject(ho::HGDIOBJ) = ccall((:DeleteObject, Gdi32), BOOL, (HGDIOBJ,), ho)
_CreateSolidBrush(color::COLORREF) = ccall((:CreateSolidBrush, Gdi32), HBRUSH, (COLORREF,), color)
_FillRect(hDC::HDC, lprc, hbr::HBRUSH) = ccall((:FillRect, User32), Cint, (HDC, Ptr{RECT}, HBRUSH), hDC, lprc, hbr)

function myWndProc(
    hwnd::WindowsAndMessaging_HWND, 
    uMsg::UInt32, 
    wParam::WindowsAndMessaging_WPARAM, 
    lParam::WindowsAndMessaging_LPARAM)::SystemServices_LRESULT

    # println("Msg: $uMsg")
    if uMsg == WMS.WM_CREATE
        println("WM_CREATE")
    elseif uMsg == WMS.WM_DESTROY
        PostQuitMessage(Int32(0))
        return SystemServices_LRESULT(0)
    elseif uMsg == WMS.WM_PAINT


        ps = PAINTSTRUCT( 0, false, RECT(0, 0, 0, 0), false, false, (zeros(BYTE,32)...,) )
        rps = Ref(ps) # BeginPaint will modify the ref, not the immutable original
        hdc = _BeginPaint(hwnd.Value, unsafe_convert(LPPAINTSTRUCT, rps))
        # @info "Paint $(rps[].rcPaint)"
        hbr = _CreateSolidBrush(_RGB(rand(BYTE), rand(BYTE), rand(BYTE)))
        _FillRect(hdc, Ref(rps[].rcPaint), hbr)
        _DeleteObject(hbr)
        _EndPaint(hwnd.Value, rps)



        # ps = Gdi_PAINTSTRUCT(
        #     Gdi_HDC(C_NULL),
        #     SystemServices_BOOL(FALSE),
        #     DisplayDevices_RECT(0,0,0,0),
        #     SystemServices_BOOL(FALSE),
        #     SystemServices_BOOL(FALSE),
        #     tuple(zeros(UInt8, 32)...)
        # )
        # rps = Ref(ps)
        # hdc = BeginPaint(hwnd, unsafe_convert(Ptr{Gdi_PAINTSTRUCT}, rps))
        # @show rps[]
        # println("paint $(rps[].rcPaint)")
        # # hbr = CreateSolidBrush(RGB(rand(UInt8), rand(UInt8), rand(UInt8)))
        # rcp = rps[].rcPaint
        # rect = DisplayDevices_RECT(rcp.left, rcp.top, rcp.right, rcp.bottom)
        # # rect = DisplayDevices_RECT(Int32(0), Int32(0), Int32(640), Int32(480))
        # # @show rect
        # # @show FillRect(hdc, unsafe_convert(Ptr{DisplayDevices_RECT}, Ref(rect)), hbr)
        # FillRect(hdc, unsafe_convert(Ptr{DisplayDevices_RECT}, Ref(rect)), Gdi_HBRUSH(COLORS.COLOR_ACTIVECAPTION + 1))
        # # DeleteObject(Ptr{Cvoid}(hbr.Value))
        # # pps = Ptr{Gdi_PAINTSTRUCT}(rps[])
        # EndPaint(hwnd, unsafe_convert(Ptr{Gdi_PAINTSTRUCT}, rps))
        return SystemServices_LRESULT(0)
    end

    return DefWindowProcW(hwnd, uMsg, wParam, lParam)
end

convertFunctionToJulia(winmd, "SystemServices.Apis", "GetModuleHandleExW")
rmod = Ref(Ptr{Cvoid}(C_NULL))
GetModuleHandleExW(UInt32(0), Ptr{UInt16}(0), rmod)
hinst = SystemServices_HINSTANCE(rmod[])
@show hinst; println()

const HINST_NULL = SystemServices_HINSTANCE(0)
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadIconW")
hicon = LoadIconW(HINST_NULL, Ptr{UInt16}(UInt(IDIS.IDI_INFORMATION)))
@show hicon; println()
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadCursorW")
hcursor = LoadCursorW(HINST_NULL, Ptr{UInt16}(UInt(IDCS.IDC_ARROW)))
@show hcursor; println()

classname = L"Julia Window Class"
# TODO Support string conversion in a constructor 
# TODO Support zero-init'd structs
wc = WindowsAndMessaging_WNDCLASSEXW(
    sizeof(WindowsAndMessaging_WNDCLASSEXW),
    CSS.CS_HREDRAW | CSS.CS_VREDRAW,
    @wndproc(myWndProc),
    Int32(0),
    Int32(0),
    hinst,
    hicon,
    hcursor,
    # Gdi_HBRUSH(COLORS.COLOR_ACTIVECAPTION + 1),
    Gdi_HBRUSH(0),
    Ptr{UInt16}(0),
    unsafe_convert(Ptr{UInt16}, classname),
    Gdi_HICON(0)
)
@show wc; println()

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "RegisterClassExW")
# TODO Support Ref(struct) -> ptr conversion in the wrapper
@show RegisterClassExW(unsafe_convert(Ptr{WindowsAndMessaging_WNDCLASSEXW}, Ref(wc)))

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "CreateWindowExW")
const SWS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(SW_(?!._))", "SW")
windowtitle = L"Window Title"
@show hwnd = CreateWindowExW(
    UInt32(0), 
    unsafe_convert(Ptr{UInt16}, classname), 
    unsafe_convert(Ptr{UInt16}, windowtitle), 
    WSS.WS_OVERLAPPEDWINDOW, 
    CWS.CW_USEDEFAULT, 
    CWS.CW_USEDEFAULT, 
    Int32(640), 
    Int32(480), 
    WindowsAndMessaging_HWND(0), 
    MenusAndResources_HMENU(0), 
    hinst, 
    Ptr{Cvoid}(C_NULL))

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "ShowWindow")
ShowWindow(hwnd, SWS.SW_SHOWNORMAL)

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "GetMessageW")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "TranslateMessage")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "DispatchMessageW")

msg = WindowsAndMessaging_MSG(
    WindowsAndMessaging_HWND(0), 
    UInt32(0), 
    WindowsAndMessaging_WPARAM(0), 
    WindowsAndMessaging_LPARAM(0), 
    UInt32(0), 
    DisplayDevices_POINT(Int32(0), Int32(0)))
pmsg = unsafe_convert(Ptr{WindowsAndMessaging_MSG}, Ref(msg));
while GetMessageW(pmsg, WindowsAndMessaging_HWND(0), UInt32(0), UInt32(0)).Value != 0
    TranslateMessage(pmsg)
    DispatchMessageW(pmsg)
end

println("Done")
