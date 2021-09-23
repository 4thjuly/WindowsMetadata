include("winmd.jl")

winmd = Winmd()
# createStructType(winmd, "Windows.Win32.Gdi.HICON")
# dump(Windows_Win32_Gdi_HICON)

convertTypeToJulia(winmd, "Windows.Win32.WindowsAndMessaging.WNDCLASSEXW")
dump(Windows_Win32_WindowsAndMessaging_WNDCLASSEXW)
println()

convertTypeToJulia(winmd, "Windows.Win32.Gdi.PAINTSTRUCT")
dump(Windows_Win32_Gdi_PAINTSTRUCT)
println()

