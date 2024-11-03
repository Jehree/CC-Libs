package.path = package.path .. ";../?.lua"
CmdLib = require("libraries.command_line_library.command_line_library")
Vec3Lib = require("libraries.vector3_library.vector3_library")
Smove = require("libraries.vector3_library.smove")


local miningDir = Vec3Lib.north
local sweepingDir = Vec3Lib.east
local pullyComputerId = 4

local config = {}

local function main()

    UpdateConfigTable()

    --Smove.resetPositionData()
    rednet.open("left")

    CmdLib.createCommand("set_x_limit", "sets x mining limit", SetConfigParameter, "xLimit")
    CmdLib.createCommand("set_z_limit", "sets z mining limit", SetConfigParameter, "zLimit")
    CmdLib.createCommand("set_y_start", "sets y starting pos. can be used to resume if program crashes", SetConfigParameter, "yStart")
    CmdLib.createCommand("start", "begin quarrying", Quarry)
    CmdLib.createCommand("lower_pully", "lower storage pully", LowerPully, true)
    CmdLib.createCommand("return_pully", "return pully to top of quarry", ReturnPully)
    CmdLib.createCommand("offload", "offloads inventory to pully chest", OffloadInventory)
    CmdLib.createCommand("refuel", "sends turtle to 0,0,0 to wait for fuel", Refuel)
    CmdLib.createCommand("resume", "resumes an in progress quarry", Resume)

    CmdLib.listenForCommands("Enter quarry command: ", "quarry program terminated!")


end


function LowerPully(skipTimer)

    rednet.send(pullyComputerId, "lower_pully")

    local timeSeconds = 0
    local timeExcededMessageSent = false
    local maxTimeBeforeMessage = 240

    if skipTimer then return end

    repeat
        if not timeExcededMessageSent and timeSeconds >= maxTimeBeforeMessage then
            ReturnPully()
            sleep(2)
            Smove.moveToAxisPoint(Axis.Y, 0)
            error("turtle had to wait too long for pully!")
        end

        sleep(1)
        timeSeconds = timeSeconds + 1
        local exists, params = turtle.inspectUp()

    until exists and params.name == "minecraft:chest"
end


function ReturnPully()
    rednet.send(pullyComputerId, "return_pully")
end


function LongWaitMessage()
    rednet.send(pullyComputerId, "long_wait_message")
end


function RequestRefuel()
    rednet.send(pullyComputerId, "refuel_please")
end


function Quarry()
    while true do
        MineRow()

        ToggleMiningDir()

        Sweep()
    end
end


function SetResumePos(resumePos)
    config.resume_pos = resumePos
    config.resume_mining_dir = miningDir
    config.resume_sweeping_dir = sweepingDir
    SaveTable(config, "quarry/config.txt")
end


function Resume()
    Refuel()

    if turtle.getFuelLevel() <= GetMinSafeFuelLevel() * 2 then
        error("Need more fuel!! Place some in my inventory please (not the fuel chest, I'll only use that when I resurface for fuel while quarrying)")
    end

    ReturnToResumePos()
    Quarry()
end


function ReturnToResumePos()
    Smove.moveToAxisPoint(Axis.X, config.resume_pos.x, nil, true)
    Smove.moveToAxisPoint(Axis.Z, config.resume_pos.z, nil, true)
    Smove.moveToAxisPoint(Axis.Y, config.resume_pos.y, nil, true)
    miningDir = config.resume_mining_dir
    sweepingDir = config.resume_sweeping_dir
end


function TurtleIsFull()
    for i = 1, 16, 1 do
        if turtle.getItemDetail(i) == nil then
            return false
        end
    end

    return true
end


function GetMinSafeFuelLevel()
    return (math.abs(Smove.getTurtlePos().y) + (config.xLimit +1) * (config.zLimit +1))
end


function RefuelNeeded()
    if turtle.getFuelLevel() <= GetMinSafeFuelLevel() then
        return true
    end
    return false
end


function OffloadInventory(dontReturnToResumePos)
    Refuel()

    SetResumePos(Smove.getTurtlePos())

    Smove.move(MoveDirection.UP, 1, true)
    Smove.moveToAxisPoint(Axis.X, 0, nil, true)
    Smove.moveToAxisPoint(Axis.Z, 0, nil, true)

    LowerPully()
    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.dropUp()
    end
    ReturnPully()

    if dontReturnToResumePos then return end

    ReturnToResumePos()
    Smove.face(miningDir)
end


function Refuel()
    for i = 1, 16, 1 do
        turtle.select(i)
        local itemInSlot = turtle.getItemDetail(i)
        if itemInSlot and itemInSlot.name ~= "minecraft:coal" then
            turtle.refuel()
        end
    end
end


function SetConfigParameter(key)
    write("Enter value: ")
    local input = read()

    if not input then return end

    config[key] = tonumber(input)
    SaveTable(config, "quarry/config.txt")

    return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
end


function UpdateConfigTable()
    config = GetTable("quarry/config.txt")
end


function MineRow()
    Smove.face(miningDir)

    while true do
        local ghostForwardMove = Smove.moveGhost(MoveDirection.FORWARD)
        if ghostForwardMove.z < 0 then return end
        if ghostForwardMove.z > config.zLimit then return end

        if RefuelNeeded() then
            Refuel()

            if RefuelNeeded() then
                SurfaceForFuel()
            end
        end

        if TurtleIsFull() then
            OffloadInventory()
        end

        Smove.move(MoveDirection.FORWARD, 1, true)
    end
end


function SurfaceForFuel()
    SetResumePos(Smove.getTurtlePos())

    OffloadInventory(true)
    sleep(2)

    Smove.moveToAxisPoint(Axis.Y, 0)

    Smove.face(Vec3Lib.south)

    while true do
        local fuelChestIsEmpty = not turtle.suck()

        if fuelChestIsEmpty then
            if turtle.getFuelLevel() <= GetMinSafeFuelLevel() * 2 then
                error("Need fuel and fuel chest is empty!")
            end
            break
        end

        if turtle.getFuelLevel() >= turtle.getFuelLimit() then break end

        Refuel()
    end

    ReturnToResumePos()
end


function Sweep()
    Smove.face(sweepingDir)

    local ghostForwardMove = Smove.moveGhost(MoveDirection.FORWARD)

    if ghostForwardMove.x > config.xLimit or ghostForwardMove.x < 0 then
        ToggleSweepingDir()
        Smove.face(miningDir)
        Smove.move(MoveDirection.DOWN, 1, true)
    else
        Smove.move(MoveDirection.FORWARD, 1, true)
        Smove.face(miningDir)
    end
end


function ToggleMiningDir()
    miningDir = NewVector3(0,0,-miningDir.z)
end


function ToggleSweepingDir()
    sweepingDir = NewVector3(-sweepingDir.x,0,0)
end


main()
