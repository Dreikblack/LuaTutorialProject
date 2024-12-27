if debuggee ~= nil then
    Print("Error: Lua debugger is already initialized.")
    return
end

local json = require 'System/dkjson'
if json == nil then
    Print("Error: Failed to load JSON library.")
    return
end
debuggee = require 'System/vscode-debuggee'
local startResult, breakerType = debuggee.start(json)
if startResult == false then
    Print("Error: Failed to start Lua debugger.")
    debuggee = nil
end