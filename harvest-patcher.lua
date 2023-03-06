local luna = require "lua_modules.luna"
local json = require "cjson"

---@class patch
---@field name string
---@field address string
---@field description string
---@field expected string
---@field value string

---@param binaryName string
---@param patches patch[]
local function patchBinary(binaryName, patches)
    local sourceBinary = io.open(("bin/%s.exe"):format(binaryName), "rb")
    local outputName = "harvest_" .. binaryName
    
    if not sourceBinary then
        print("Error, \"" .. binaryName .. "\" not found in bin folder.")
    else
        local patchedBinary = io.open(("build/%s.exe"):format(outputName), "wb")
        assert(patchedBinary, "Error, could not open " .. outputName .. ".exe for writing.")

        print("Patching " .. outputName .. "...")
        patchedBinary:write(sourceBinary:read("*a"))
        for _, patch in pairs(patches) do
            -- Move patched binary cursor to specified address
            patchedBinary:seek("set", tonumber(patch.address))

            -- Get patch value info
            local value = patch.value:fromhex()

            -- Move source binary cursor to specified address
            sourceBinary:seek("set", tonumber(patch.address))
            local originalValue = sourceBinary:read(#value)

            local expectedValue = patch.expected:fromhex()
            local isPatchApplicable = originalValue ~= expectedValue
            local patchStatus = isPatchApplicable and "FAIL" or "OK"
            -- Show current patch
            io.stderr:write(" - " .. patch.description .. " ")
            --io.stderr:write("(" .. patch.address .. ") ")
            io.stderr:write("[" .. patchStatus .. "]\n")
            if patchStatus == "FAIL" then
                io.stderr:write("   Expected: " .. tostring(expectedValue):tohex() .. "\n")
                io.stderr:write("   Actual: " .. tostring(originalValue):tohex() .. "\n")
            end
            --print("Original value: " .. tostring(originalValue):tohex())
            --print("Raw value:", value)
            --print("String value:", tostring(value):tohex())

            if not isPatchApplicable then
                -- Patch output binary
                patchedBinary:write(value)
            end
            -- patchedBinary:seek("set", tonumber(patch.address))
            -- print("Written value:", patchedBinary:read(#value))
        end
        sourceBinary:close()
        patchedBinary:close()
        print("")
    end
end

---@type patch[]
local toolPatches = json.decode(luna.file.read("tool-patches.json"))

---@type patch[]
local sapienPatches = json.decode(luna.file.read("sapien-patches.json"))

---@type patch[]
local h1aSapienPatches = json.decode(luna.file.read("h1a-sapien-patches.json"))

patchBinary("tool", toolPatches)
patchBinary("sapien", sapienPatches)
patchBinary("h1a_sapien", h1aSapienPatches)
