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
println()

stuff = convertClassFieldsToJulia(winmd, "SystemServices.Apis")
# dump(SystemServices_Apis)
# @show convertTypeToJulia(winmd, "SystemServices.Apis")
