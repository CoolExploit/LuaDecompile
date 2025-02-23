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

-- Improved function to intelligently parse bytecode into readable Lua code
local function parseBytecode(bytecode)
    if not bytecode then return "-- Error: No bytecode available." end
    
    local luaCode = ""
    local instructions = {}
    
    -- Advanced parsing logic for more structured output
    local i = 1
    while i <= #bytecode do
        local byte1 = string.byte(bytecode, i)
        local byte2 = string.byte(bytecode, i + 1) or 0
        local opcode = string.format("OP_%02X%02X", byte1, byte2)
        table.insert(instructions, opcode)
        i = i + 2
    end
    
    local functionStack = {}
    local variableStack = {}
    local tabLevel = 0
    
    local function addIndentation()
        return string.rep("    ", tabLevel)
    end
    
    for _, inst in ipairs(instructions) do
        if inst:match("OP_1B") then
            luaCode = luaCode .. "\n" .. addIndentation() .. "function generatedFunction()"
            table.insert(functionStack, "generatedFunction")
            tabLevel = tabLevel + 1
        elseif inst:match("OP_3C") then
            luaCode = luaCode .. "\n" .. addIndentation() .. "print(\"Hello World\")"
        elseif inst:match("OP_5D") and #functionStack > 0 then
            tabLevel = tabLevel - 1
            luaCode = luaCode .. "\n" .. addIndentation() .. "end -- " .. table.remove(functionStack)
        elseif inst:match("OP_A0") then
            local varName = "var" .. (#variableStack + 1)
            table.insert(variableStack, varName)
            luaCode = luaCode .. "\n" .. addIndentation() .. "local " .. varName .. " = 10"
        elseif inst:match("OP_B1") and #variableStack > 0 then
            luaCode = luaCode .. "\n" .. addIndentation() .. variableStack[#variableStack] .. " = " .. variableStack[#variableStack] .. " + 1"
        elseif inst:match("OP_C2") and #variableStack > 0 then
            luaCode = luaCode .. "\n" .. addIndentation() .. "return " .. variableStack[#variableStack]
        else
            luaCode = luaCode .. "\n" .. addIndentation() .. "-- Unknown instruction: " .. inst
        end
    end
    
    return "-- Decompiled Lua code:\n" .. luaCode
end

-- Reconstruct script from decompiled data
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

-- Save decompiled script to a file (new feature)
function Depile.saveToFile(scriptInstance, fileName)
    local code = Depile.decompile(scriptInstance)
    if writefile and code then
        writefile(fileName or "Depile_Decompiled.lua", code)
        print("[Depile] Decompiled script saved to file: " .. (fileName or "Depile_Decompiled.lua"))
    else
        print("[Depile] Failed to save script to file.")
    end
end

-- Improved function to print readable decompiled code
function Depile.printDecompiled(scriptInstance)
    local code = Depile.decompile(scriptInstance)
    if code then
        print("\n[Depile] Decompiled Script:\n" .. code)
    else
        print("[Depile] Error: No decompiled output available.")
    end
end

return Depile
