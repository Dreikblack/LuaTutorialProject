function string.split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

--This function is used to handle errors that occur as a result of an Invoke() function.
function LuaErrorHandler(message)
	local s = string.split(message,":")
    print(s)
end