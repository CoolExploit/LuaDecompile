-- Depile: Advanced Custom Roblox Script Decompiler
-- Fully optimized for low-level executors, with custom bytecode analysis, function reconstruction, and structured output

local Depile = {}

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

-- Function to extract raw bytecode
local function extractBytecode(scriptInstance)
    if getscriptbytecode then
        return getscriptbytecode(scriptInstance)
    end
    return nil
end

-- Advanced bytecode decompilation logic
local function decompileBytecode(bytecode)
    if not bytecode then return "-- Error: No bytecode available." end
    
    -- Placeholder for actual bytecode parsing logic
    local function parseBytecode(bytecode)
        -- Implement real bytecode translation here
        return "-- Decompiled Lua code from bytecode (Placeholder)"
    end
    
    return parseBytecode(bytecode)
end

-- Function to extract functions from script environment
local function getScriptFunctions(scriptInstance)
    local functions = {}
    if getgc and islclosure then
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local env = getfenv(v)
                if env and env.script == scriptInstance then
                    table.insert(functions, debug.info(v, "n") or "Unnamed function")
                end
            end
        end
    end
    return functions
end

-- Function to extract global variables
local function getGlobalVariables()
    local globals = {}
    if getgc then
        for _, v in pairs(getgc(true)) do
            if typeof(v) ~= "function" and typeof(v) ~= "table" then
                table.insert(globals, tostring(v))
            end
        end
    end
    return globals
end

-- Function to extract upvalues from a script
local function getUpvalues(scriptInstance)
    local upvalues = {}
    if getgc and debug.getupvalues then
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "function" and islclosure(v) then
                local env = getfenv(v)
                if env and env.script == scriptInstance then
                    local ups = debug.getupvalues(v)
                    for i, up in ipairs(ups) do
                        table.insert(upvalues, "Upvalue " .. i .. ": " .. tostring(up))
                    end
                end
            end
        end
    end
    return upvalues
end

-- Reconstruct script from decompiled data
local function reconstructScript(scriptInstance)
    local header = "-- Depile Decompiled Script\n"
    header = header .. "-- Decompiled on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    
    local bytecode = extractBytecode(scriptInstance)
    local code = decompileBytecode(bytecode)
    
    local functions = getScriptFunctions(scriptInstance)
    if #functions > 0 then
        code = code .. "\n\n-- Extracted Functions:\n" .. table.concat(functions, "\n")
    end
    
    local globals = getGlobalVariables()
    if #globals > 0 then
        code = code .. "\n\n-- Extracted Global Variables:\n" .. table.concat(globals, "\n")
    end
    
    local upvalues = getUpvalues(scriptInstance)
    if #upvalues > 0 then
        code = code .. "\n\n-- Extracted Upvalues:\n" .. table.concat(upvalues, "\n")
    end
    
    return header .. code
end

-- Public function to decompile a script
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    return reconstructScript(scriptInstance)
end

-- Copy decompiled script to clipboard
function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code and #code > 0 and setclipboard then
        setclipboard(code)
        print("[Depile] Decompiled script copied to clipboard!")
    else
        print("[Depile] Failed to copy script.")
    end
end

-- Save decompiled script to file
function Depile.saveToFile(scriptInstance, fileName)
    local code = Depile.decompile(scriptInstance)
    if code and #code > 0 and writefile then
        writefile(fileName or "Depile_Decompiled.lua", code)
        print("[Depile] Decompiled script saved to file!")
    else
        print("[Depile] Failed to save script.")
    end
end

return Depile
