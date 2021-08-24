include("metadataimport.jl")

mdi = metadataDispenser() |> metadataImport
tdWAMApis = findTypeDef(mdi, "Windows.Win32.WindowsAndMessaging.Apis")
methodDef = findMethod(mdi, tdWAMApis, "RegisterClassExW")
@show methodDef
println()

(moduleref, importname) = getPInvokeMap(mdi, methodDef)
@show importname
println()

moduleName = getModuleRefProps(mdi, moduleref)
@show moduleName
println()

paramDef = getParamForMethodIndex(mdi, methodDef, 1) 
paramName = getParamProps(mdi, paramDef)
@show paramName
println()

sig = getMethodProps(mdi, methodDef)
@show sig
println()

typedref = uncompressSig(@view sig[6:7])
@show typedref
@show isValidToken(mdi, typedref)

structname = getTypeRefName(typedref)
@show structname
println()

structToken = findTypeDef(structname)
@show structToken
println()

fields = enumFields(structToken)
showFields(fields)
println()

# drill in to last field
name = ((fields[end] |> fieldProps).sigblob |> sigblobtoTypeInfo).subtype |> getName
@show name
name |> findTypeDef |> enumFields |> showFields