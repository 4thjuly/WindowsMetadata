include("metadataimport.jl")

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

# TODO - decompose sig properly and lookup last paramCount

# typedref = uncompressToken(@view sig[6:7])
typeinfo = methodSigblobtoTypeInfo(sigblob)
typedref = typeinfo.paramType

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
name = ((fields[end] |> fieldProps).sigblob |> fieldSigblobtoTypeInfo).type |> getName
@show name
name |> findTypeDef |> enumFields |> showFields