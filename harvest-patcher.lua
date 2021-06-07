local inspect = require "inspect"
local glue = require "glue"
local json = require "cjson"

---@class patch
---@field name string
---@field address string
---@field description string
---@field value string

---@type patch[]
local patches = json.decode(glue.readfile("patches.json", "t"))

local tool = io.open("bin/tool.exe", "rb")
local harvest = io.open("bin/harvest.exe", "rwb")
if (tool and harvest) then
    harvest:write(tool:read("*a"))
    for _, patch in pairs(patches) do
        print(patch.description, patch.address)
        harvest:seek("set", tonumber(patch.address))
        local value = glue.string.fromhex(patch.value)
        print("Raw value:", value)
        print("String value:", glue.string.tohex(tostring(value)))
        harvest:write(value)
        harvest:seek("set", tonumber(patch.address))
        print("Written value:", harvest:read(#value))
    end
end
tool:close()
harvest:close()