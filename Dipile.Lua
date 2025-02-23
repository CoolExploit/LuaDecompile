-- Depile: Advanced Roblox Script Decompiler (Enhanced Version)
-- Fully optimized for low-level executors, with fallback mechanisms

local Depile = {}

-- Function to check if an instance is a script
local function isScript(obj)
    return obj and (obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script"))
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

-- Function to decompile a script with structured output
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end

    local startTime = tick()
    local code = tryDecompile(scriptInstance) or "[Depile] Error: Unable to decompile script."
    local timeTaken = string.format("%.2f", (tick() - startTime)) -- Time in seconds

    return string.format([[
-- Depile: Advanced Roblox Script Decompiler
-- Decompiled with Depile
-- Decompiled on %s
-- Time taken: %s seconds

%s
]], os.date("%Y-%m-%d %H:%M:%S"), timeTaken, code)
end

-- Function to copy decompiled script to clipboard
function Depile.setToClipboard(scriptInstance)
    local result = Depile.decompile(scriptInstance)
    if isSupported(setclipboard) then
        setclipboard(result)
        print("[Depile] Decompiled script copied to clipboard!")
    else
        print("[Depile] Error: Clipboard function not available.")
    end
end

return Depile
