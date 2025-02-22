-- Depile: Advanced Roblox Script Decompiler
-- Upload this script to GitHub and use its raw URL in your main script

local Depile = {}

-- Function to check if an instance is a script
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript"))
end

-- Function to get full name of an instance
local function getFullName(instance)
    local path = {}
    while instance and instance ~= game do
        table.insert(path, 1, instance.Name)
        instance = instance.Parent
    end
    return "game." .. table.concat(path, ".")
end

-- Function to handle different data types
local function handleDataType(data)
    local dataType = typeof(data)
    if dataType == "string" then
        return "\"" .. data .. "\""
    elseif dataType == "number" or dataType == "boolean" then
        return tostring(data)
    elseif dataType == "Instance" then
        return getFullName(data)
    elseif dataType == "table" then
        local elements = {}
        for k, v in pairs(data) do
            table.insert(elements, "[" .. handleDataType(k) .. "] = " .. handleDataType(v))
        end
        return "{" .. table.concat(elements, ", ") .. "}"
    else
        return "nil -- Unsupported type: " .. dataType
    end
end

-- Function to extract and format function details
local function decompileFunction(func)
    if typeof(func) ~= "function" then return "nil -- Not a function" end
    local success, constants = pcall(debug.getconstants, func)
    local success2, upvalues = pcall(debug.getupvalues, func)
    
    local funcInfo = "function(...)
    "
    if success then
        funcInfo = funcInfo .. "    -- Constants: " .. handleDataType(constants) .. "\n"
    end
    if success2 then
        funcInfo = funcInfo .. "    -- Upvalues: " .. handleDataType(upvalues) .. "\n"
    end
    funcInfo = funcInfo .. "end"
    return funcInfo
end

-- Function to decompile a script
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    
    local success, result = pcall(decompile, scriptInstance)
    if success then
        return result
    else
        local functions = {}
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) and getfenv(v).script == scriptInstance then
                table.insert(functions, decompileFunction(v))
            end
        end
        return "[Depile] Decompiled manually:\n" .. table.concat(functions, "\n\n")
    end
end

-- Function to copy decompiled script to clipboard
function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code then
        setclipboard(code)
        print("[Depile] Decompiled script copied to clipboard!")
    else
        print("[Depile] Failed to copy script to clipboard.")
    end
end

return Depile
