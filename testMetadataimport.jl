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

structname = getTypeRefName(typedref)
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
println()

# convert 
undotname = convertTypeNameToJulia(name)
fields = name |> findTypeDef |> enumFields
fps = fieldProps(fields[1])
@show fps.name
typeinfo = fps.sigblob |> fieldSigblobtoTypeInfo
@show typeinfo.type
jt = convertTypeToJulia(ELEMENT_TYPE(typeinfo.type))
createStructType(undotname, [(fps.name, jt)])

# Test
hicon = Windows_Win32_Gdi_HICON(42)
dump(hicon)

