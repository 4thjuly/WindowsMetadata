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

function myWndProc(
    hwnd::WindowsAndMessaging_HWND, 
    uMsg::UInt32, 
    wParam::WindowsAndMessaging_WPARAM, 
    lParam::WindowsAndMessaging_LPARAM)::SystemServices_LRESULT

    ps = Gdi_PAINTSTRUCT(
        Gdi_HDC(C_NULL),
        SystemServices_BOOL(FALSE),
        DisplayDevices_RECT(0,0,0,0),
        SystemServices_BOOL(FALSE),
        SystemServices_BOOL(FALSE),
        tuple(zeros(UInt8, 32)...)
    )

    println("Msg: $uMsg")
    if uMsg == WMS.WM_CREATE
        println("WM_CREATE")
    elseif uMsg == WMS.WM_DESTROY
        PostQuitMessage(Int32(0))
        return 0
    elseif uMsg == WMS.WM_PAINT
        rps = Ref(ps)
        hdc = BeginPaint(hwnd, rps)
        println("paint $(paint.rect)")
        hbr = CreateSolidBrush(RGB(rand(UInt8), rand(UInt8), rand(UInt8)))
        FillRect(hdc, rps[].rect, hbr)
        DeleteObject(hbr)
        pps = Ptr{Gdi_PAINTSTRUCT}(rps[])
        EndPaint(hwnd, pps)
        return 0
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
    Gdi_HBRUSH(COLORS.COLOR_WINDOW + 1),
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

# msg = WindowsAndMessaging_MSG(

# )

