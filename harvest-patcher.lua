local inspect = require "inspect"
local glue = require "glue"
local json = require "cjson"

---@class patch
---@field name string
---@field address string
---@field description string
---@field value string

---@type patch[]
local toolPatches = json.decode(glue.readfile("tool-patches.json", "t"))

---@type patch[]
local sapienPatches = json.decode(glue.readfile("sapien-patches.json", "t"))

local function patchBinary(binaryName, patches)
    local sourceBinary = io.open(("bin/%s.exe"):format(binaryName), "rb")
    local outputName
    if (binaryName == "tool") then
        outputName = "harvest"
    else
        outputName = "harvest_" .. binaryName
    end
    local patchedBinary = io.open(("bin/%s.exe"):format(outputName), "wb")
    if (sourceBinary and patchedBinary) then
        print("Patching " .. binaryName .. ".exe...")
        print("Output " .. outputName .. ".exe")
        patchedBinary:write(sourceBinary:read("*a"))
        for _, patch in pairs(patches) do
            -- Show current patch
            print(patch.description, patch.address)

            -- Move patched binary cursor to specified address
            patchedBinary:seek("set", tonumber(patch.address))

            -- Get patch value info
            local value = glue.string.fromhex(patch.value)

            -- Move source binary cursor to specified address
            sourceBinary:seek("set", tonumber(patch.address))
            local originalValue = sourceBinary:read(#value)

            
            print("Original value: " .. glue.string.tohex(tostring(originalValue)))
            print("Raw value:", value)
            print("String value:", glue.string.tohex(tostring(value)))

            -- Patch output binary
            patchedBinary:write(value)
            --patchedBinary:seek("set", tonumber(patch.address))
            --print("Written value:", patchedBinary:read(#value))
        end
        sourceBinary:close()
        patchedBinary:close()
        print("Done!\n")
    else
        print("Error, " .. binaryName .. " not found.")
    end
end

patchBinary("tool", toolPatches)
patchBinary("sapien", sapienPatches)
