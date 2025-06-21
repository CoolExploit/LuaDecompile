-- Depile.Parser - Roblox Luau Bytecode Disassembler (No Compatibility Required)

-- === Full Luau Opcode Database ===
local OPCODE_NAMES = {
    [0] = "MOVE", [1] = "LOADK", [2] = "LOADKX", [3] = "LOADBOOL", [4] = "LOADNIL",
    [5] = "GETUPVAL", [6] = "GETTABUP", [7] = "GETTABLE", [8] = "SETTABUP", [9] = "SETUPVAL",
    [10] = "SETTABLE", [11] = "NEWTABLE", [12] = "SELF", [13] = "ADD", [14] = "SUB",
    [15] = "MUL", [16] = "DIV", [17] = "MOD", [18] = "POW", [19] = "UNM", [20] = "NOT",
    [21] = "LEN", [22] = "CONCAT", [23] = "JMP", [24] = "EQ", [25] = "LT", [26] = "LE",
    [27] = "TEST", [28] = "TESTSET", [29] = "CALL", [30] = "TAILCALL", [31] = "RETURN",
    [32] = "FORLOOP", [33] = "FORPREP", [34] = "TFORCALL", [35] = "TFORLOOP", [36] = "SETLIST",
    [37] = "CLOSURE", [38] = "VARARG", [39] = "EXTRAARG", [40] = "PREPVARARGS", [41] = "LOADKNUM",
    [42] = "LOADKSTR", [43] = "LOADNIL_N", [44] = "GETIMPORT", [45] = "GETTABLE_N", [46] = "SETTABLE_N",
    [47] = "GETTABLE_S", [48] = "SETTABLE_S", [49] = "GETTABUP_N", [50] = "SETTABUP_N",
    [51] = "GETTABUP_S", [52] = "SETTABUP_S", [53] = "NEWCLOSURE", [54] = "NAMECALL",
    [55] = "CALL_M", [56] = "RETURN_M", [57] = "GETTABLEKS", [58] = "SETTABLEKS", [59] = "GETTABLEN",
    [60] = "SETTABLEN", [61] = "GETVARARGS", [62] = "DUPCLOSURE", [63] = "FORNPREP",
    [64] = "FORNLOOP", [65] = "FASTCALL", [66] = "COVERAGE", [67] = "CAPTURE",
    [68] = "FASTCALL1", [69] = "FASTCALL2", [70] = "FASTCALL2K", [71] = "FASTCALL3",
    [72] = "FORGLOOP", [73] = "FORGPREP_INEXT", [74] = "FORGLOOP_INEXT", [75] = "FORGPREP_NEXT",
    [76] = "FORGLOOP_NEXT", [77] = "GETVARARGS_R", [78] = "FASTCALL1_R", [79] = "FASTCALL2_R",
    [80] = "FASTCALL2K_R", [81] = "FASTCALL3_R", [82] = "JUMPBACK", [83] = "JUMPXEQKNIL",
    [84] = "JUMPXEQKB", [85] = "JUMPXEQKN", [86] = "JUMPXEQKS", [87] = "JUMPXNEQKNIL",
    [88] = "JUMPXNEQKB", [89] = "JUMPXNEQKN", [90] = "JUMPXNEQKS", [91] = "JUMPX",
    [92] = "JUMPXEQ", [93] = "JUMPXNE", [94] = "JUMPXLT", [95] = "JUMPXLE"
}

-- Complete format table for all opcodes
local OPCODE_FORMATS = {
    [0] = "iABC", [1] = "iABx", [2] = "iABx", [3] = "iABC", [4] = "iABC",
    [5] = "iABC", [6] = "iABC", [7] = "iABC", [8] = "iABC", [9] = "iABC",
    [10] = "iABC", [11] = "iABC", [12] = "iABC", [13] = "iABC", [14] = "iABC",
    [15] = "iABC", [16] = "iABC", [17] = "iABC", [18] = "iABC", [19] = "iABC",
    [20] = "iABC", [21] = "iABC", [22] = "iABC", [23] = "iAsBx", [24] = "iABC",
    [25] = "iABC", [26] = "iABC", [27] = "iABC", [28] = "iABC", [29] = "iABC",
    [30] = "iABC", [31] = "iABC", [32] = "iAsBx", [33] = "iAsBx", [34] = "iABC",
    [35] = "iAsBx", [36] = "iABC", [37] = "iABx", [38] = "iABC", [39] = "iAx",
    [40] = "iABC", [41] = "iABx", [42] = "iABx", [43] = "iABC", [44] = "iABx",
    [45] = "iABC", [46] = "iABC", [47] = "iABC", [48] = "iABC", [49] = "iABC",
    [50] = "iABC", [51] = "iABC", [52] = "iABC", [53] = "iABx", [54] = "iABC",
    [55] = "iABC", [56] = "iABC", [57] = "iABC", [58] = "iABC", [59] = "iABC",
    [60] = "iABC", [61] = "iABC", [62] = "iABx", [63] = "iAsBx", [64] = "iAsBx",
    [65] = "iABC", [66] = "iABC", [67] = "iABC", [68] = "iABC", [69] = "iABC",
    [70] = "iABC", [71] = "iABC", [72] = "iAsBx", [73] = "iAsBx", [74] = "iAsBx",
    [75] = "iAsBx", [76] = "iAsBx", [77] = "iABC", [78] = "iABC", [79] = "iABC",
    [80] = "iABC", [81] = "iABC", [82] = "iAsBx", [83] = "iAsBx", [84] = "iAsBx",
    [85] = "iAsBx", [86] = "iAsBx", [87] = "iAsBx", [88] = "iAsBx", [89] = "iAsBx",
    [90] = "iAsBx", [91] = "iAsBx", [92] = "iAsBx", [93] = "iAsBx", [94] = "iAsBx",
    [95] = "iAsBx"
}

-- Bit manipulation functions for maximum compatibility
local band, rshift

-- Try to use available bit libraries first
local bit = bit32 or bit
if bit and bit.band then
    band = bit.band
    rshift = bit.rshift or function(a, n) return math.floor(a / (2^n)) end
else
    -- Manual bit operations fallback for maximum compatibility
    function band(a, b)
        local result = 0
        local power = 1
        while a > 0 or b > 0 do
            if (a % 2 == 1) and (b % 2 == 1) then
                result = result + power
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            power = power * 2
        end
        return result
    end
    
    function rshift(a, n)
        return math.floor(a / (2^n))
    end
end

local function decode(inst)
    local opcode = band(inst, 0x3F)
    local A = band(rshift(inst, 6), 0xFF)
    local C = band(rshift(inst, 14), 0x1FF)
    local B = band(rshift(inst, 23), 0x1FF)
    local Bx = band(rshift(inst, 14), 0x3FFFF)
    local sBx = Bx - 131071
    local Ax = rshift(inst, 6)

    return {
        opcode = opcode,
        A = A, B = B, C = C,
        Bx = Bx, sBx = sBx, Ax = Ax,
        format = OPCODE_FORMATS[opcode] or "iABC",
        name = OPCODE_NAMES[opcode] or ("UNKNOWN_" .. tostring(opcode)),
        raw = inst
    }
end

local Parser = {}

function Parser.parse(bytecode)
    -- Use type() instead of typeof() for compatibility
    if type(bytecode) ~= "string" then
        return nil, "[Depile.Parser] Invalid bytecode - expected string"
    end

    if #bytecode == 0 then
        return nil, "[Depile.Parser] Empty bytecode"
    end

    local instructions = {}
    local pos = 1
    
    while pos <= #bytecode do
        -- Check if we have enough bytes for a complete instruction
        if pos + 3 > #bytecode then
            break
        end
        
        local chunk = bytecode:sub(pos, pos + 3)
        
        -- Verify we got 4 bytes
        if #chunk ~= 4 then
            break
        end

        local success, inst = pcall(string.unpack, "<I4", chunk)
        if not success then
            return nil, "[Depile.Parser] Failed to unpack instruction at position " .. pos
        end

        local decoded = decode(inst)
        decoded.index = #instructions + 1
        decoded.position = pos
        table.insert(instructions, decoded)
        
        pos = pos + 4
    end

    if #instructions == 0 then
        return nil, "[Depile.Parser] No valid instructions found"
    end

    return instructions
end

function Parser.formatInstructions(instructions)
    if not instructions or #instructions == 0 then
        return "[Depile.Parser] No instructions to format"
    end

    local out = {}
    for _, inst in ipairs(instructions) do
        local line = string.format("[%03d] %-15s A=%-3d B=%-3d C=%-3d sBx=%-6d (format=%s)",
            inst.index, inst.name, inst.A, inst.B, inst.C, inst.sBx, inst.format)
        table.insert(out, line)
    end
    return table.concat(out, "\n")
end

-- Additional utility function to get instruction details
function Parser.getInstructionInfo(opcode)
    return {
        name = OPCODE_NAMES[opcode] or ("UNKNOWN_" .. tostring(opcode)),
        format = OPCODE_FORMATS[opcode] or "iABC"
    }
end

-- Function to validate bytecode format
function Parser.validateBytecode(bytecode)
    if type(bytecode) ~= "string" then
        return false, "Bytecode must be a string"
    end
    
    if #bytecode == 0 then
        return false, "Bytecode cannot be empty"
    end
    
    if #bytecode % 4 ~= 0 then
        return false, "Bytecode length must be divisible by 4"
    end
    
    return true
end

return Parser
