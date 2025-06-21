# 📦 Depile – Roblox Lua Decompiler
Depile is a powerful and executor-compatible Roblox Lua decompiler designed to convert live script bytecode into human-readable Lua source code. It is built for educational and debugging purposes, supporting a wide range of executors with fallback and compatibility detection.

# ⚙️ Features
✅ Script decompilation from in-game LocalScript, ModuleScript, or Script instances

🔍 Bytecode parsing and instruction decoding based on real Luau opcodes

📋 Supports most major executor APIs (with dynamic compatibility checks)

🧠 Function reconstruction and simple control flow rebuilding

💾 Optional clipboard copy and file saving (only if supported by the executor)

📄 Fully modular structure with Parser, Rebuilder, and Compatibility modules

🧰 Zero fake output — all decompiled results are based on real bytecode

# 📌 Requirements
A Lua executor with support for one or more of:

getscriptbytecode

getconstants, getprotos, getupvalues, etc.

setclipboard, writefile (for output options)
