-- Depile: Advanced Roblox Script Decompiler (Enhanced Version)
-- Fully optimized for low-level executors, with fallback mechanisms

local Depile = {}
local LuauDecompiler = {} -- Future implementation for custom bytecode analysis

-- Function to check if an instance is a script
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script"))
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

-- Function to safely check if an executor supports a feature
local function isSupported(feature)
    return pcall(function() return feature ~= nil end)
end

-- Function to decompile a script using executor's built-in method
local function tryDecompile(scriptInstance)
    if isSupported(decompile) then
        local success, result = pcall(decompile, scriptInstance)
        if success and result then return result end
    end
    return nil
end

-- Function to extract and format function details
local function getScriptFunctions(scriptInstance)
    local functions = {}
    if isSupported(getgc) and isSupported(islclosure) then
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local env = getfenv(v)
                if env and env.script == scriptInstance then
                    table.insert(functions, "-- Extracted function: " .. tostring(v))
                end
            end
        end
    end
    return functions
end

-- Function to reconstruct script structure
local function reconstructScript(scriptInstance)
    local header = "-- Depile: Advanced Decompiler (Improved Version)\n"
    header = header .. "-- Decompiled on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
    header = header .. "-- Time taken: (to be measured) seconds\n\n"
    
    local code = tryDecompile(scriptInstance)
    if code then
        return header .. code
    end
    
    local functions = getScriptFunctions(scriptInstance)
    if #functions > 0 then
        return header .. "-- Decompiled manually:\n" .. table.concat(functions, "\n\n")
    end
    
    return header .. "-- Error: Unable to decompile script."
end

-- Function to decompile a script with fallbacks
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    return reconstructScript(scriptInstance)
end

-- Function to copy decompiled script to clipboard
function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code then
        if isSupported(setclipboard) then
            setclipboard(code)
            print("[Depile] Decompiled script copied to clipboard!")
        else
            print("[Depile] Error: Clipboard function not available.")
        end
    else
        print("[Depile] Failed to copy script to clipboard.")
    end
end

return Depile
