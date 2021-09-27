include("winmd.jl")

const FALSE = Int(false)
const TRUE = Int(1)

winmd = Winmd("Windows.Win32")

@show convertTypeToJulia(winmd, "WindowsAndMessaging.WNDCLASSEXW")
dump(WindowsAndMessaging_WNDCLASSEXW)
println()
@show convertTypeToJulia(winmd, "Gdi.PAINTSTRUCT")
dump(Gdi_PAINTSTRUCT)
println()

# TODO - convert single value structs into Julie equivs

ps = Gdi_PAINTSTRUCT(
    Gdi_HDC(C_NULL),
    SystemServices_BOOL(FALSE),
    DisplayDevices_RECT(0,0,0,0),
    SystemServices_BOOL(FALSE),
    SystemServices_BOOL(FALSE),
    tuple(zeros(UInt8, 32)...)
)
dump(ps)
println()

const ws = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WS_(?!._))", "WS")
const cs = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CS_(?!._))", "CS")
const cw = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CW_(?!._))", "CW")
const idi = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDI_(?!._))", "IDI")
const idc = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDC_(?!._))", "IDC")
const wm = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WM_(?!._))", "WM")

convertFunctionToJulia(winmd, "SystemServices.Apis", "GetModuleHandleW")

