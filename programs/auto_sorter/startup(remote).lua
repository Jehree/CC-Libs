--rename to startup.lua
package.path = package.path .. ";../?.lua"
CmdLib = require("libraries.command_line_library.command_line_library")
require("libraries.misc_utils.utils")

local function main()
    CmdLib.wirelessSetup(2, os.getComputerID())
    CmdLib.enableWirelessSending()
end

main()
