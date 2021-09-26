include("metadataimport-wrapper.jl")
include("winmd.jl")

mdi = metadataDispenser() |> metadataImport
tdWAMApis = findTypeDef(mdi, "Windows.Win32.WindowsAndMessaging.Apis")
mdRegClass = findMethod(mdi, tdWAMApis, "RegisterClassExW")
@show mdRegClass
println()

(moduleref, importname) = getPInvokeMap(mdi, mdRegClass)
@show importname
println()

moduleName = getModuleRefProps(mdi, moduleref)
@show moduleName
println()

paramDef = getParamForMethodIndex(mdi, mdRegClass, 1) 
paramName = getParamProps(mdi, paramDef)
@show paramName
println()

sigblob = getMethodProps(mdi, mdRegClass)
@show sigblob
println()

typeinfo = methodSigblobtoTypeInfo(sigblob)
@show typeinfo
typedref = typeinfo[3]

@show typedref
@show isValidToken(mdi, typedref)

structname = getTypeRefName(mdi, typedref)
@show structname
println()

# Dump struct
function showFields(fields::Vector{mdFieldDef})
    for field in fields
        name, sigblob = fieldProps(mdi, field)
        @show name
        @show sigblob
        @show fieldSigblobtoTypeInfo(sigblob)
    end
end

structToken = findTypeDef(mdi, structname)
@show structToken
tdprops = getTypeDefProps(mdi, structToken)
@show tdprops.extends
@show getTypeRefName(mdi, tdprops.extends)
println()

fields = enumFields(mdi, structToken)
showFields(fields)
println()

# Drill in to last field
_, sigblob = fieldProps(mdi, fields[end])
name = getName(mdi, fieldSigblobtoTypeInfo(sigblob)[1])
@show name
enumFields(mdi, findTypeDef(mdi, name)) |> showFields
println()

# convert 
undotname = convertTypeNameToJulia(name)
name, sigblob = fieldProps(mdi, enumFields(mdi, findTypeDef(mdi, name))[1])
@show name
typeinfo = fieldSigblobtoTypeInfo(sigblob)
@show typeinfo[1]
# jt = convertTypeToJulia(mdi, typeinfo[1])
# createStructType(undotname, [(fps.name, jt)])

# Test
# hicon = Windows_Win32_Gdi_HICON(42)
# dump(hicon)
# println()

# WndProc
_, sigblob = fieldProps(mdi, fields[3])
field3type,_ = fieldSigblobtoTypeInfo(sigblob)
@show field3type
name = getName(mdi, field3type)
@show name
tdWndProc = findTypeDef(mdi, name)
name, ext = getTypeDefProps(mdi, tdWndProc)
extendsName = getName(mdi, ext)
@show extendsName
wndprocMemnbers = enumMembers(mdi, tdWndProc)
@show wndprocMemnbers
println()

# PAINTSTRUCT
structToken = findTypeDef(mdi, "Windows.Win32.Gdi.PAINTSTRUCT")
fields = enumFields(mdi, structToken)
showFields(fields)
println()

# Enums
structToken = findTypeDef(mdi, "Windows.Win32.SystemServices.Apis")
fields = enumFields(mdi, structToken)
@show length(fields)
println()