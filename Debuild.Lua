-- Depile.Rebuilder - Advanced Luau Code Reconstructor with Enhanced Features

local Rebuilder = {}

-- Enhanced constant formatting with type detection
local function formatConstant(val)
    local t = type(val)
    if t == "string" then
        -- Escape special characters properly
        local escaped = val:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
        return '"' .. escaped .. '"'
    elseif t == "number" then
        -- Handle special number cases
        if val ~= val then return "0/0" -- NaN
        elseif val == math.huge then return "1/0" -- +Inf
        elseif val == -math.huge then return "-1/0" -- -Inf
        else return tostring(val) end
    elseif t == "boolean" then
        return tostring(val)
    elseif val == nil then
        return "nil"
    elseif t == "table" then
        return "{ --[[ table ]] }"
    else
        return tostring(val)
    end
end

-- Enhanced variable naming with context awareness
local function getVarName(n, context)
    context = context or "var"
    if n < 0 then
        return "upval_" .. math.abs(n)
    elseif context == "temp" then
        return "temp_" .. n
    elseif context == "loop" then
        return "i_" .. n
    else
        return "var_" .. n
    end
end

-- Get constant or register value
local function getValue(idx, isConstant, constants)
    if isConstant and constants[idx] then
        return formatConstant(constants[idx])
    elseif isConstant then
        return "CONST[" .. idx .. "]"
    else
        return getVarName(idx)
    end
end

-- Check if value is a constant (K bit flag)
local function isK(val)
    return val > 255 -- In Luau, constants have K bit set (> 255)
end

-- Advanced control flow tracking
local ControlFlow = {
    stack = {},
    labels = {},
    jumps = {}
}

function ControlFlow:push(blockType, startIdx, endIdx)
    table.insert(self.stack, {
        type = blockType,
        start = startIdx,
        ending = endIdx,
        indent = #self.stack
    })
end

function ControlFlow:pop()
    return table.remove(self.stack)
end

function ControlFlow:getCurrentBlock()
    return self.stack[#self.stack]
end

function ControlFlow:addJump(fromIdx, toIdx, condition)
    table.insert(self.jumps, {
        from = fromIdx,
        to = toIdx,
        condition = condition
    })
end

-- Main rebuilder function with comprehensive instruction support
function Rebuilder.rebuild(instructions, constants)
    constants = constants or {}
    local output = {}
    local currentIndent = 0
    
    -- Reset control flow
    ControlFlow.stack = {}
    ControlFlow.labels = {}
    ControlFlow.jumps = {}
    
    local function addLine(text, extraIndent)
        extraIndent = extraIndent or 0
        local indent = string.rep("    ", currentIndent + extraIndent)
        table.insert(output, indent .. text)
    end
    
    local function increaseIndent()
        currentIndent = currentIndent + 1
    end
    
    local function decreaseIndent()
        currentIndent = math.max(0, currentIndent - 1)
    end
    
    -- Pre-process jumps for better control flow detection
    for i, inst in ipairs(instructions) do
        if inst.name:match("JMP") or inst.name:match("FOR") then
            local target = i + inst.sBx + 1
            ControlFlow:addJump(i, target, inst.name)
        end
    end
    
    -- Process each instruction
    for i, inst in ipairs(instructions) do
        local op = inst.name
        local A, B, C = inst.A, inst.B, inst.C
        local Bx, sBx, Ax = inst.Bx, inst.sBx, inst.Ax
        
        -- Add instruction comment for debugging
        if Rebuilder.debug then
            addLine(string.format("-- [%03d] %s A=%d B=%d C=%d", i, op, A, B, C), 0)
        end
        
        -- Handle different instruction types
        if op == "MOVE" then
            addLine(string.format("%s = %s", getVarName(A), getVarName(B)))
            
        elseif op == "LOADK" then
            local konstant = constants[Bx] and formatConstant(constants[Bx]) or ("CONST[" .. Bx .. "]")
            addLine(string.format("local %s = %s", getVarName(A), konstant))
            
        elseif op == "LOADKX" then
            -- Extended constant loading
            addLine(string.format("local %s = CONST_EXT[%d]", getVarName(A), Ax))
            
        elseif op == "LOADBOOL" then
            local value = B ~= 0 and "true" or "false"
            addLine(string.format("local %s = %s", getVarName(A), value))
            if C ~= 0 then
                addLine("-- skip next instruction")
            end
            
        elseif op == "LOADNIL" then
            local count = B == 0 and 1 or B
            if count == 1 then
                addLine(string.format("local %s = nil", getVarName(A)))
            else
                local vars = {}
                for j = 0, count - 1 do
                    table.insert(vars, getVarName(A + j))
                end
                addLine(string.format("local %s = nil", table.concat(vars, ", ")))
            end
            
        elseif op == "LOADNIL_N" then
            local count = A
            addLine(string.format("-- load nil to %d registers", count))
            
        elseif op == "GETUPVAL" then
            addLine(string.format("local %s = upval[%d]", getVarName(A), B))
            
        elseif op == "SETUPVAL" then
            addLine(string.format("upval[%d] = %s", B, getVarName(A)))
            
        elseif op == "GETTABUP" then
            local key = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = upval[%d][%s]", getVarName(A), B, key))
            
        elseif op == "SETTABUP" then
            local key = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local val = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("upval[%d][%s] = %s", A, key, val))
            
        elseif op == "GETTABLE" then
            local key = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s[%s]", getVarName(A), getVarName(B), key))
            
        elseif op == "SETTABLE" then
            local key = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local val = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s[%s] = %s", getVarName(A), key, val))
            
        elseif op == "GETTABLEKS" then
            local key = constants[Ax] and formatConstant(constants[Ax]) or ("CONST[" .. Ax .. "]")
            addLine(string.format("%s = %s[%s]", getVarName(A), getVarName(B), key))
            
        elseif op == "SETTABLEKS" then
            local key = constants[Ax] and formatConstant(constants[Ax]) or ("CONST[" .. Ax .. "]")
            addLine(string.format("%s[%s] = %s", getVarName(A), key, getVarName(B)))
            
        elseif op == "GETTABLEN" then
            addLine(string.format("%s = %s[%d]", getVarName(A), getVarName(B), C + 1))
            
        elseif op == "SETTABLEN" then
            addLine(string.format("%s[%d] = %s", getVarName(A), B + 1, getVarName(C)))
            
        elseif op == "NEWTABLE" then
            local arraySize = B
            local hashSize = C
            if arraySize > 0 or hashSize > 0 then
                addLine(string.format("local %s = {} -- array:%d hash:%d", getVarName(A), arraySize, hashSize))
            else
                addLine(string.format("local %s = {}", getVarName(A)))
            end
            
        elseif op == "SELF" then
            local key = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s, %s = %s, %s[%s]", getVarName(A + 1), getVarName(A), getVarName(B), getVarName(B), key))
            
        -- Arithmetic operations
        elseif op == "ADD" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s + %s", getVarName(A), left, right))
            
        elseif op == "SUB" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s - %s", getVarName(A), left, right))
            
        elseif op == "MUL" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s * %s", getVarName(A), left, right))
            
        elseif op == "DIV" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s / %s", getVarName(A), left, right))
            
        elseif op == "MOD" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s %% %s", getVarName(A), left, right))
            
        elseif op == "POW" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            addLine(string.format("%s = %s ^ %s", getVarName(A), left, right))
            
        elseif op == "UNM" then
            addLine(string.format("%s = -%s", getVarName(A), getVarName(B)))
            
        elseif op == "NOT" then
            addLine(string.format("%s = not %s", getVarName(A), getVarName(B)))
            
        elseif op == "LEN" then
            addLine(string.format("%s = #%s", getVarName(A), getVarName(B)))
            
        elseif op == "CONCAT" then
            local vars = {}
            for j = B, C do
                table.insert(vars, getVarName(j))
            end
            addLine(string.format("%s = %s", getVarName(A), table.concat(vars, " .. ")))
            
        -- Control flow
        elseif op == "JMP" then
            addLine(string.format("-- jump to instruction %d (%+d)", i + sBx + 1, sBx))
            
        elseif op == "EQ" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            local condition = A == 0 and "~=" or "=="
            addLine(string.format("if %s %s %s then", left, condition, right))
            increaseIndent()
            
        elseif op == "LT" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            local condition = A == 0 and ">=" or "<"
            addLine(string.format("if %s %s %s then", left, condition, right))
            increaseIndent()
            
        elseif op == "LE" then
            local left = isK(B) and getValue(B - 256, true, constants) or getVarName(B)
            local right = isK(C) and getValue(C - 256, true, constants) or getVarName(C)
            local condition = A == 0 and ">" or "<="
            addLine(string.format("if %s %s %s then", left, condition, right))
            increaseIndent()
            
        elseif op == "TEST" then
            local condition = C == 0 and "not " or ""
            addLine(string.format("if %s%s then", condition, getVarName(A)))
            increaseIndent()
            
        elseif op == "TESTSET" then
            local condition = C == 0 and "not " or ""
            addLine(string.format("%s = %s", getVarName(A), getVarName(B)))
            addLine(string.format("if %s%s then", condition, getVarName(A)))
            increaseIndent()
            
        -- Function calls
        elseif op == "CALL" then
            local func = getVarName(A)
            local args = {}
            local nargs = B == 0 and "..." or (B - 1)
            local nrets = C == 0 and "..." or (C - 1)
            
            if B > 1 then
                for j = 1, B - 1 do
                    table.insert(args, getVarName(A + j))
                end
                addLine(string.format("%s(%s) -- %d returns", func, table.concat(args, ", "), nrets))
            else
                addLine(string.format("%s() -- %d returns", func, nrets))
            end
            
        elseif op == "TAILCALL" then
            local func = getVarName(A)
            local args = {}
            if B > 1 then
                for j = 1, B - 1 do
                    table.insert(args, getVarName(A + j))
                end
                addLine(string.format("return %s(%s)", func, table.concat(args, ", ")))
            else
                addLine(string.format("return %s()", func))
            end
            
        elseif op == "RETURN" then
            if B == 0 then
                addLine("return ...")
            elseif B == 1 then
                addLine("return")
            else
                local rets = {}
                for j = 0, B - 2 do
                    table.insert(rets, getVarName(A + j))
                end
                addLine(string.format("return %s", table.concat(rets, ", ")))
            end
            
        elseif op == "RETURN_M" then
            addLine("return -- multret")
            
        -- Loops
        elseif op == "FORPREP" then
            addLine(string.format("-- for loop prep: %s to %s step %s", 
                getVarName(A), getVarName(A + 1), getVarName(A + 2)))
            addLine(string.format("for %s = %s, %s, %s do", 
                getVarName(A + 3, "loop"), getVarName(A), getVarName(A + 1), getVarName(A + 2)))
            increaseIndent()
            
        elseif op == "FORLOOP" then
            decreaseIndent()
            addLine("end -- for loop")
            
        elseif op == "FORNPREP" then
            addLine(string.format("-- numeric for loop prep (jump %+d)", sBx))
            
        elseif op == "FORNLOOP" then
            addLine(string.format("-- numeric for loop continue (jump %+d)", sBx))
            
        elseif op == "TFORCALL" then
            addLine(string.format("-- iterator call: %s, %s, %s = %s(%s, %s)", 
                getVarName(A + 3), getVarName(A + 4), getVarName(A + 5),
                getVarName(A), getVarName(A + 1), getVarName(A + 2)))
                
        elseif op == "TFORLOOP" then
            addLine(string.format("if %s ~= nil then", getVarName(A + 1)))
            increaseIndent()
            addLine(string.format("%s = %s", getVarName(A), getVarName(A + 1)))
            addLine(string.format("-- continue loop (jump %+d)", sBx))
            decreaseIndent()
            addLine("end")
            
        -- Closures
        elseif op == "CLOSURE" then
            addLine(string.format("local %s = function() -- function prototype %d", getVarName(A), Bx))
            increaseIndent()
            
        elseif op == "NEWCLOSURE" then
            addLine(string.format("local %s = function() -- new closure prototype %d", getVarName(A), Bx))
            increaseIndent()
            
        elseif op == "DUPCLOSURE" then
            addLine(string.format("local %s = function() -- duplicate closure %d", getVarName(A), Bx))
            
        -- Fast calls (Luau optimizations)
        elseif op == "FASTCALL" then
            addLine(string.format("-- fast call %d", A))
            
        elseif op == "FASTCALL1" then
            addLine(string.format("-- fast call1 %d(%s)", A, getVarName(B)))
            
        elseif op == "FASTCALL2" then
            addLine(string.format("-- fast call2 %d(%s, %s)", A, getVarName(B), getVarName(C)))
            
        elseif op == "FASTCALL2K" then
            local arg2 = constants[C] and formatConstant(constants[C]) or ("CONST[" .. C .. "]")
            addLine(string.format("-- fast call2k %d(%s, %s)", A, getVarName(B), arg2))
            
        elseif op == "NAMECALL" then
            local method = constants[Ax] and formatConstant(constants[Ax]) or ("METHOD[" .. Ax .. "]")
            addLine(string.format("%s = %s:%s", getVarName(A), getVarName(B), method))
            
        -- Import system
        elseif op == "GETIMPORT" then
            local import = constants[Bx] and formatConstant(constants[Bx]) or ("IMPORT[" .. Bx .. "]")
            addLine(string.format("local %s = %s -- import", getVarName(A), import))
            
        -- Variable arguments
        elseif op == "VARARG" then
            if B == 0 then
                addLine(string.format("%s = ...", getVarName(A)))
            else
                local vars = {}
                for j = 0, B - 2 do
                    table.insert(vars, getVarName(A + j))
                end
                addLine(string.format("%s = ... -- %d args", table.concat(vars, ", "), B - 1))
            end
            
        elseif op == "GETVARARGS" then
            addLine(string.format("-- get varargs count=%d", B))
            
        elseif op == "PREPVARARGS" then
            addLine(string.format("-- prepare varargs %d", A))
            
        -- Jump variants
        elseif op:match("^JUMPX") then
            addLine(string.format("-- extended jump: %s (offset %+d)", op, sBx))
            
        else
            -- Unknown or unhandled instruction
            addLine(string.format("-- [%s] A=%d B=%d C=%d Bx=%d sBx=%d", op, A, B, C, Bx, sBx))
        end
    end
    
    return table.concat(output, "\n")
end

-- Debug mode toggle
Rebuilder.debug = false

-- Set constants table
function Rebuilder.setConstants(consts)
    constants = consts or {}
end

-- Enhanced formatting with syntax highlighting hints
function Rebuilder.rebuildWithHighlighting(instructions, constants)
    local code = Rebuilder.rebuild(instructions, constants)
    return code -- Could add syntax highlighting markers here
end

-- Statistics about the rebuilt code
function Rebuilder.getStatistics(instructions)
    local stats = {
        totalInstructions = #instructions,
        instructionTypes = {},
        complexity = 0
    }
    
    for _, inst in ipairs(instructions) do
        local op = inst.name
        stats.instructionTypes[op] = (stats.instructionTypes[op] or 0) + 1
        
        -- Simple complexity metric
        if op:match("CALL") or op:match("LOOP") or op:match("JMP") then
            stats.complexity = stats.complexity + 1
        end
    end
    
    return stats
end

return Rebuilder
