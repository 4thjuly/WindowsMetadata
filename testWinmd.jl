include("winmd.jl")

import Base.unsafe_convert, Base.cconvert
import Base.GC.@preserve

RGB(r::UInt8, g::UInt8, b::UInt8)::UInt32 = (UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b))

# TODO 
# Generate converters for Handle types (handle.Value)
# Macro-ize 
# Type-stabalize the lib, cleanup names
# Support type aliases?
winmd = Winmd("Windows.Win32")

# Defines
const WSS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WS_(?!._))", "WS")
const CSS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CS_(?!._))", "CS")
const CWS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CW_(?!._))", "CW")
const IDIS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDI_(?!._))", "IDI")
const IDCS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDC_(?!._))", "IDC")
const WMS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WM_(?!._))", "WM")
const COLORS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(COLOR_(?!._))", "COLOR")

# TODO Convert delegates to callbacks, until then do this by hand
macro wndproc(wp) return :(@cfunction($wp, LRESULT, (HWND, UInt32, WPARAM, LPARAM))) end

convertFunctionToJulia(winmd, "SystemServices.Apis", "GetModuleHandleExW")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "PostQuitMessage")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "DefWindowProcW")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "SetTimer")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "KillTimer")
convertFunctionToJulia(winmd, "Gdi.Apis", "BeginPaint")
convertFunctionToJulia(winmd, "Gdi.Apis", "CreateSolidBrush")
convertFunctionToJulia(winmd, "Gdi.Apis", "FillRect")
convertFunctionToJulia(winmd, "Gdi.Apis", "DeleteObject")
convertFunctionToJulia(winmd, "Gdi.Apis", "EndPaint")
convertFunctionToJulia(winmd, "SystemServices.Apis", "SetProcessWorkingSetSize")
convertFunctionToJulia(winmd, "SystemServices.Apis", "GetCurrentProcess")

convertTypeToJulia(winmd, "WindowsAndMessaging", "WNDCLASSEXW")

# Flush workingset after startup to make leak finding easier
const IDT_FLUSH_WORKINGSET = 1

function myWndProc( hwnd::HWND, uMsg::UInt32, wParam::WPARAM, lParam::LPARAM)::LRESULT
    if uMsg == WMS.WM_CREATE
        println("WM_CREATE")
        SetTimer(hwnd, UInt64(IDT_FLUSH_WORKINGSET), UInt32(1000), C_NULL)
    elseif uMsg == WMS.WM_DESTROY
        PostQuitMessage(Int32(0))
        return LRESULT(0)
    elseif uMsg == WMS.WM_TIMER
        if (wParam.Value == IDT_FLUSH_WORKINGSET)
            KillTimer(hwnd, UInt64(IDT_FLUSH_WORKINGSET))
            SetProcessWorkingSetSize(HANDLE(-1), typemax(UInt64), typemax(UInt64))
            return LRESULT(0)
        end
    elseif uMsg == WMS.WM_PAINT
        ps = PAINTSTRUCT(HDC(0), BOOL(false), RECT(0,0,0,0), BOOL(false), BOOL(false), tuple(zeros(UInt8, 32)...))
        rps = Ref(ps)
        hdc = BeginPaint(hwnd, rps)
        hbr = CreateSolidBrush(RGB(rand(UInt8), rand(UInt8), rand(UInt8)))
        FillRect(hdc, Ref(rps[].rcPaint), hbr)
        DeleteObject(Ptr{Cvoid}(hbr.Value))
        EndPaint(hwnd, rps)
        return LRESULT(0)
    end

    return DefWindowProcW(hwnd, uMsg, wParam, lParam)
end

rmod = Ref(Ptr{Cvoid}(0))
@show GetModuleHandleExW(UInt32(0), Ptr{UInt16}(0), rmod)
hinst = HINSTANCE(rmod[])
@show hinst

const HINST_NULL = HINSTANCE(0)
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadIconW")
hicon = LoadIconW(HINST_NULL, Ptr{UInt16}(UInt(IDIS.IDI_INFORMATION)))
@show hicon
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadCursorW")
hcursor = LoadCursorW(HINST_NULL, Ptr{UInt16}(UInt(IDCS.IDC_ARROW)))
@show hcursor

classname = L"Julia Window Class"
# TODO Support string conversion in a constructor 
# TODO Support zero-init'd structs
wc = WNDCLASSEXW(
    sizeof(WNDCLASSEXW),
    CSS.CS_HREDRAW | CSS.CS_VREDRAW,
    @wndproc(myWndProc),
    Int32(0),
    Int32(0),
    hinst,
    hicon,
    hcursor,
    HBRUSH(0),
    C_NULL,
    pointer(classname),
    HICON(0)
)

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "RegisterClassExW")
class = RegisterClassExW(unsafe_convert(Ptr{WNDCLASSEXW}, Ref(wc)))
@show class

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "CreateWindowExW")
const SWS = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(SW_(?!._))", "SW")
windowtitle = L"Julia Win32 App"
hwnd = CreateWindowExW(
    UInt32(0), 
    pointer(classname), 
    pointer(windowtitle), 
    WSS.WS_OVERLAPPEDWINDOW, 
    CWS.CW_USEDEFAULT, 
    CWS.CW_USEDEFAULT, 
    Int32(640), 
    Int32(480), 
    HWND(0), 
    HMENU(0), 
    hinst, 
    C_NULL)
@show hwnd

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "ShowWindow")
ShowWindow(hwnd, SWS.SW_SHOWNORMAL)

convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "GetMessageW")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "TranslateMessage")
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "DispatchMessageW")

msg = MSG(HWND(0), UInt32(0), WPARAM(0), LPARAM(0), UInt32(0), POINT(Int32(0), Int32(0)))
rmsg = Ref(msg)

while GetMessageW(rmsg, HWND(0), UInt32(0), UInt32(0)).Value != 0
    TranslateMessage(rmsg)
    DispatchMessageW(rmsg)
end

println("Done")
