macro make_struct(name, fields)
    fexp = [:($(Symbol(x[1]))::$(Symbol(x[2]))) for x in eval(fields)]
    quote 
        struct $(esc(Symbol(name)))
            $(map(esc, fexp)...)
        end
    end
end

function make_struct(name, fields)
    fexp = [:($(Symbol(x[1]))::$(Symbol(x[2]))) for x in fields]
    sexp = quote 
        struct $(Symbol(name))
            $(fexp...)
        end
    end
    eval(sexp)
end

# Compile time
@make_struct("TestStruct1", [["x","Int"], ["y", "String"], ["z", "Bool"]])
dump(TestStruct1)

# Runtime
make_struct("TestStruct2", [["foo","Int"], ["bar", "String"], ["fred", "Bool"]])
dump(TestStruct2)
