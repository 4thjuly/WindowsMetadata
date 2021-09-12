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
typedref = typeinfo.paramType

@show typedref
@show isValidToken(mdi, typedref)

structname = getTypeRefName(mdi, typedref)
@show structname
println()

# Dump struct
function showFields(fields::Vector{mdFieldDef})
    for field in fields
        fp = fieldProps(field)
        @show fp.name
        @show fp.sigblob
        @show fieldSigblobtoTypeInfo(fp.sigblob)
    end
end

structToken = findTypeDef(mdi, structname)
@show structToken
println()
fields = enumFields(mdi, structToken)
showFields(fields)
println()

# Drill in to last field
name = getName(mdi, ((fields[end] |> fieldProps).sigblob |> fieldSigblobtoTypeInfo).type)
@show name
enumFields(mdi, findTypeDef(mdi, name)) |> showFields
println()

# convert 
undotname = convertTypeNameToJulia(name)
fps = fieldProps(enumFields(mdi, findTypeDef(mdi, name))[1])
@show fps.name
typeinfo = fps.sigblob |> fieldSigblobtoTypeInfo
@show typeinfo.type
jt = convertPrimitiveTypeToJulia(ELEMENT_TYPE(typeinfo.type))
createStructType(undotname, [(fps.name, jt)])

# Test
hicon = Windows_Win32_Gdi_HICON(42)
dump(hicon)
println()

# WndProc
field3type = ((fields[3] |> fieldProps).sigblob |> fieldSigblobtoTypeInfo).type
@show field3type
name = getName(mdi, field3type)
@show name
tdWndProc = findTypeDef(mdi, name)
name, extends = getTypeDefProps(mdi, tdWndProc)
extendsName = getName(mdi, extends)
@show extendsName
wndprocMemnbers = enumMembers(mdi, tdWndProc)
@show wndprocMemnbers


