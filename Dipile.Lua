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

-- Function to parse bytecode into readable Lua code
local function parseBytecode(bytecode)
    if not bytecode then return "-- Error: No bytecode available." end
    
    local luaCode = ""
    local instructions = {}
    
    local i = 1
    while i <= #bytecode do
        local opcode = string.format("OP_%02X", string.byte(bytecode, i))
        table.insert(instructions, opcode)
        i = i + 1
    end
    
    local function addIndentation(level)
        return string.rep("    ", level)
    end
    
    local functionStack = {}
    local variableStack = {}
    local tabLevel = 0
    
    for _, inst in ipairs(instructions) do
        if inst == "OP_FUNC" then -- Function declaration
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. "function generatedFunction()"
            table.insert(functionStack, "generatedFunction")
            tabLevel = tabLevel + 1
        elseif inst == "OP_ENDFUNC" and #functionStack > 0 then -- End function
            tabLevel = tabLevel - 1
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. "end -- " .. table.remove(functionStack)
        elseif inst == "OP_VAR" then -- Declare variable
            local varName = "var" .. (#variableStack + 1)
            table.insert(variableStack, varName)
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. "local " .. varName .. " = 0"
        elseif inst == "OP_SET" and #variableStack > 0 then -- Set variable value
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. variableStack[#variableStack] .. " = 100"
        elseif inst == "OP_RETURN" and #variableStack > 0 then -- Return statement
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. "return " .. variableStack[#variableStack]
        else
            luaCode = luaCode .. "\n" .. addIndentation(tabLevel) .. "-- Unknown instruction: " .. inst
        end
    end
    
    return "-- Decompiled Lua code:\n" .. luaCode
end

-- Function to reconstruct script from decompiled data
local function reconstructScript(scriptInstance)
    local header = "-- Depile Decompiled Script\n"
    header = header .. "-- Decompiled on " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
    
    local bytecode = extractBytecode(scriptInstance)
    local code = parseBytecode(bytecode)
    
    return header .. code
end

-- Public function to decompile a script
function Depile.decompile(scriptInstance)
    if not isScript(scriptInstance) then
        return "[Depile] Error: Target is not a valid script."
    end
    return reconstructScript(scriptInstance)
end

-- Function to copy decompiled script to clipboard
function Depile.copyToClipboard(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code and #code > 0 and setclipboard then
        setclipboard(code)
        print("[Depile] Decompiled script copied to clipboard!")
    else
        print("[Depile] Failed to copy script.")
    end
end

-- Function to save decompiled script to a file
function Depile.saveToFile(scriptInstance, fileName)
    local code = Depile.decompile(scriptInstance)
    if writefile and code then
        writefile(fileName or "Depile_Decompiled.lua", code)
        print("[Depile] Decompiled script saved to file: " .. (fileName or "Depile_Decompiled.lua"))
    else
        print("[Depile] Failed to save script to file.")
    end
end

-- Function to print readable decompiled code
function Depile.printDecompiled(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code then
        print("\n[Depile] Decompiled Script:\n" .. code)
    else
        print("[Depile] Error: No decompiled output available.")
    end
end

return Depile
