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
@show ps
# dump(ps)
println()

const ws = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WS_(?!._))", "WS")
const cs = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CS_(?!._))", "CS")
const cw = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(CW_(?!._))", "CW")
const idi = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDI_(?!._))", "IDI")
const idc = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(IDC_(?!._))", "IDC")
const wm = convertClassFieldsToJulia(winmd, "SystemServices.Apis", r"^(WM_(?!._))", "WM")

# function GetModuleHandleExW(flags::UInt32, lpModuleName::Ptr{UInt16}, phModule::Ref{Ptr{Cvoid}})
#     ccall((:GetModuleHandleExW, "kernel32"), Bool, (UInt32, Ptr{UInt16}, Ref{Ptr{Cvoid}}), flags, lpModuleName, phModule)
# end

# rmod = Ref(Ptr{Cvoid}(C_NULL))
# @show GetModuleHandleExW(UInt32(0), Ptr{UInt16}(0), rmod)
# @show rmod[]

convertFunctionToJulia(winmd, "SystemServices.Apis", "GetModuleHandleExW")
