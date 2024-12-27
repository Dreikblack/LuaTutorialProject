-- This code modifies component functions so they will automatically call FireOutputs() after they are execuated

function __WrapComponentMethod__(component, k, v)
    if type(k)=="string" and type(v)=="function" then--add all functions into a function table
        if type(component.__functable__) ~= "table" then component.__functable__ = {} end
        component.__functable__[k] = v
        local funcname = k
        
        function __DummyFunc__(component,...)
            return __ComponentMethodWrapper__(component, funcname, ...)
        end
        
        return __DummyFunc__
    end
    return v
end

function __ComponentMethodWrapper__(component, funcname, ...) --accepts any number of arguments
    if type(component.__functable__) == "table" then
        local func = component.__functable__[funcname]
        if type(func)=="function" then
            local result = func(component, ...) --supplies all arguments to the function
            component:FireOutputs(funcname)
            return result;
        else
            Print("Error: Function table value must be a function.")
        end
    end
end