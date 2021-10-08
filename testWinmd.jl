include("winmd.jl")

const FALSE = Int(false)
const TRUE = Int(1)
macro L_str(s) transcode(Cwchar_t, s) end
RGB(r::UInt8, g::UInt8, b::UInt8)::UInt32 = (UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b))

winmd = Winmd("Windows.Win32")

convertTypeToJulia(winmd, "Gdi.PAINTSTRUCT")
convertTypeToJulia(winmd, "DisplayDevices.RECT")
convertTypeToJulia(winmd, "WindowsAndMessaging.WNDCLASSEXW")
convertTypeToJulia(winmd, "WindowsAndMessaging.MSG")

const ws = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WS_(?!._))", "WS")
const cs = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CS_(?!._))", "CS")
const cw = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CW_(?!._))", "CW")
const idi = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDI_(?!._))", "IDI")
const idc = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDC_(?!._))", "IDC")
const wm = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WM_(?!._))", "WM")

macro wndproc(wp) return :(@cfunction($wp, 
    SystemServices.LRESULT, 
    (WindowsAndMessaging.HWND, UInt32, WindowsAndMessaging.WPARAM, WindowsAndMessaging.LPARAM))) 
end

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

    # println("Msg: $uMsg")
    if uMsg == wm.WM_CREATE
        println("WM_CREATE")
    elseif uMsg == wm.WM_DESTROY
        PostQuitMessage(Int32(0))
        return 0
    elseif uMsg == wm.WM_PAINT
        rps = Ref(ps)
        hdc = BeginPaint(hwnd, rps)
        # println("paint $(paint.rect)")
        hbr = CreateSolidBrush(RGB(rand(UInt8), rand(UInt8), rand(UInt8)))
        FillRect(hdc, rps[].rect, hbr)
        DeleteObject(hbr)
        pps = Ptr{Gdi_PAINTSTRUCT}(rps[])
        EndPaint(hwnd, pps)
        return 0
    end

    return DefWindowProc(hwnd, uMsg, wParam, lParam)
end

convertFunctionToJulia(winmd, "SystemServices.Apis", "GetModuleHandleExW")
rmod = Ref(Ptr{Cvoid}(C_NULL))
GetModuleHandleExW(UInt32(0), Ptr{UInt16}(0), rmod)
hinst = SystemServices_HINSTANCE(rmod[])
@show hinst; println()

const HINST_NULL = SystemServices_HINSTANCE(Ptr{Cvoid}(C_NULL))
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadIconW")
hicon = LoadIconW(HINST_NULL, Ptr{UInt16}(UInt(idi.IDI_INFORMATION)))
@show hicon; println()
convertFunctionToJulia(winmd, "MenusAndResources.Apis", "LoadCursorW")
hcursor = LoadCursorW(HINST_NULL, Ptr{UInt16}(UInt(idc.IDC_ARROW)))
@show hcursor; println()

# wc = WindowsAndMessaging.WNDCLASSEXW(
#     length(WindowsAndMessaging.WNDCLASSEXW),
#     cs.CS_HREDRAW | cs.CS_VREDRAW,
#     @wndproc(myWndProc),
#     Int32(0),
#     Int32(0),
#     hinst,
#     hicon,
#     hcursor,
#     Gdi_HBRUSH(0),
#     Cwchar_t[]
# )

# convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "RegisterClassEx")
# RegisterClassEx(wc)

# className = L"Julia Window Class"

# hwnd = CreateWindowExW(
#     UInt32(0), 
#     className, 
#     L"Window Title", 
#     ws.WS_OVERLAPPEDWINDOW, 
#     cw.CW_USEDEFAULT, 
#     cw.CW_USEDEFAULT, 
#     512, 
#     512, 
#     0, 
#     MenusAndResources_HMENU(0), 
#     hinst, 
#     0)

# convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", "ShowWindow")
# ShowWindow(hwnd, sw.SW_SHOWNORMAL)

# msg = WindowsAndMessaging_MSG(

# )

