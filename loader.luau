-- Luau | Real | ZERO MM2 loader | Creator: Nandox | MIT
local repository = "nandox97l/zero-mm2"
local http = game:GetService("HttpService")
local metadata = http:JSONDecode(game:HttpGet("https://api.github.com/repos/" .. repository .. "/commits/main?t=" .. os.time()))
local revision = metadata.sha
assert(type(revision) == "string" and #revision == 40 and revision:match("^[a-f0-9]+$"), "ZERO MM2: GitHub nao devolveu uma versao valida.")
local environment = type(getgenv) == "function" and getgenv() or _G
environment.ZERO_MM2_SOURCE_REF = revision
local source = game:HttpGet("https://raw.githubusercontent.com/" .. repository .. "/" .. revision .. "/zero-mm2.luau")
local run, compile_error = loadstring(source, "ZERO-MM2@" .. revision)
assert(run, compile_error)
return run()
