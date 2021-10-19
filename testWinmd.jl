include("winmd.jl")

RGB(r::UInt8, g::UInt8, b::UInt8)::UInt32 = (UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b))

# TODO 
# Generate converters for Handle types (handle.Value)
# Macro-ize 
# Type-stabalize the lib, cleanup names
# Support type aliases?
winmd = Winmd("Windows.Win32")

@time begin
# Defines - these are kinda slow so allow regex filters
convertClassFieldsToJuliaConsts(winmd, "SystemServices.Apis", [ r"^(WS_(?!._))", r"^(CS_(?!._))", r"^(CW_(?!._))", r"^(IDI_(?!._))", r"^(IDC_(?!._))", r"^(WM_(?!._))", r"^(COLOR_(?!._))", r"^(SW_(?!._))"])

# TODO Convert delegates to callbacks, until then do this by hand
convertTypeToJulia(winmd, "WindowsAndMessaging", ["HWND", "WPARAM", "LPARAM"])
convertTypeToJulia(winmd, "SystemServices", "LRESULT")
macro wndproc(wp) return :(@cfunction($wp, LRESULT, (HWND, UInt32, WPARAM, LPARAM))) end

# Will also convert parameter types as needed
convertFunctionToJulia(winmd, "SystemServices.Apis", ["GetModuleHandleExW", "SetProcessWorkingSetSize", "GetCurrentProcess"])
convertFunctionToJulia(winmd, "WindowsAndMessaging.Apis", ["PostQuitMessage", "DefWindowProcW", "SetTimer", "KillTimer", "RegisterClassExW", "GetMessageW", "TranslateMessage", "DispatchMessageW", "CreateWindowExW", "ShowWindow"])
convertFunctionToJulia(winmd, "Gdi.Apis", ["BeginPaint", "CreateSolidBrush", "FillRect", "DeleteObject", "EndPaint", "UpdateWindow"])
convertFunctionToJulia(winmd, "MenusAndResources.Apis", ["LoadIconW", "LoadCursorW"])
end

# Flush workingset after startup to make leak finding easier
const IDT_FLUSH_WORKINGSET = 1

function myWndProc(hwnd::HWND, uMsg::UInt32, wParam::WPARAM, lParam::LPARAM)::LRESULT
    if uMsg == WM_CREATE
        println("WM_CREATE")
        SetTimer(hwnd, UInt64(IDT_FLUSH_WORKINGSET), UInt32(1000), C_NULL)
    elseif uMsg == WM_DESTROY
        PostQuitMessage(Int32(0))
        return LRESULT(0)
    elseif uMsg == WM_TIMER
        if (wParam.Value == IDT_FLUSH_WORKINGSET)
            KillTimer(hwnd, UInt64(IDT_FLUSH_WORKINGSET))
            SetProcessWorkingSetSize(HANDLE(-1), typemax(UInt64), typemax(UInt64))
            return LRESULT(0)
        end
    elseif uMsg == WM_PAINT
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

rmod = Ref(C_NULL)
@show GetModuleHandleExW(UInt32(0), Ptr{UInt16}(0), rmod)
hinst = HINSTANCE(rmod[])
@show hinst

const HINST_NULL = HINSTANCE(0)
hicon = LoadIconW(HINST_NULL, Ptr{UInt16}(UInt(IDI_INFORMATION)))
@show hicon
hcursor = LoadCursorW(HINST_NULL, Ptr{UInt16}(UInt(IDC_ARROW)))
@show hcursor

classname = L"Julia Window Class"
# TODO Support string conversion in a constructor 
# TODO Support zero-init'd structs
wc = WNDCLASSEXW(
    sizeof(WNDCLASSEXW),
    CS_HREDRAW | CS_VREDRAW,
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

class = RegisterClassExW(Ref(wc))
@show class

windowtitle = L"Julia Win32 App"
hwnd = CreateWindowExW(
    UInt32(0), 
    pointer(classname), 
    pointer(windowtitle), 
    WS_OVERLAPPEDWINDOW, 
    CW_USEDEFAULT, 
    CW_USEDEFAULT, 
    Int32(640), 
    Int32(480), 
    HWND(0), 
    HMENU(0), 
    hinst, 
    C_NULL)
@show hwnd

ShowWindow(hwnd, SW_SHOWNORMAL)
UpdateWindow(hwnd)

msg = MSG(HWND(0), UInt32(0), WPARAM(0), LPARAM(0), UInt32(0), POINT(Int32(0), Int32(0)))
rmsg = Ref(msg)

while GetMessageW(rmsg, HWND(0), UInt32(0), UInt32(0)).Value != 0
    TranslateMessage(rmsg)
    DispatchMessageW(rmsg)
end

println("Done")
