package.path = package.path .. ";../?.lua"
local Vec3Lib = require("libraries.vector3_library.vector3_library")
local Utils = require("libraries.vector3_library.utils")


local defaultData = {
    current_dir = NewVector3(0,0,1),
    current_pos = Vec3Lib.Zero
}

TurnDirection = {
    RIGHT = "right",
    LEFT = "left",
    AROUND = "around"
}

MoveDirection = {
    RIGHT = "right",
    LEFT = "left",
    FORWARD = "forward",
    BACKWARD = "backward",
    UP = "up",
    DOWN = "down"
}

local function getTurtleDir()
    local data = GetTable("libraries/vector3_library/data.txt")
    return data.current_dir
end


local function getTurtlePos()
    local data = GetTable("libraries/vector3_library/data.txt")
    return data.current_pos
end


local function updateDirFile(newDir)
    local data = GetTable("libraries/vector3_library/data.txt")
    data.current_dir = newDir
    SaveTable(data, "libraries/vector3_library/data.txt")
end


local function updatePosFile(newPos)
    local data = GetTable("libraries/vector3_library/data.txt")
    data.current_pos = newPos
    SaveTable(data, "libraries/vector3_library/data.txt")
end


local function resetPositionData()
    SaveTable(defaultData, "libraries/vector3_library/data.txt")
end


local function turn(turnDir)
    local oldDir = getTurtleDir()

    if turnDir == TurnDirection.RIGHT then
        turtle.turnRight()
        updateDirFile(NewVector3(oldDir.z, 0, -oldDir.x))
    end
    if turnDir == TurnDirection.LEFT then
        turtle.turnLeft()
        updateDirFile(NewVector3(-oldDir.z, 0, oldDir.x))
    end
    if turnDir == TurnDirection.AROUND then
        turtle.turnRight()
        turtle.turnRight()
        updateDirFile(NewVector3(-oldDir.x, 0, -oldDir.z))
    end


end


local function face(targetDirection)
    if targetDirection.x == 0 and targetDirection.z == 0 then return end

    local oldDir = getTurtleDir()

    local turnDirection
    if Vec3AreEqual(NewVector3(oldDir.z, 0, -oldDir.x), targetDirection) then
        turnDirection = TurnDirection.RIGHT
    else
        turnDirection = TurnDirection.LEFT
    end

    while not Vec3AreEqual(getTurtleDir(), targetDirection) do
        turn(turnDirection)
    end
end


local function getMoveDirectionTools(moveDirection)
    local forwardVector = getTurtleDir()
    local tools = {
        [MoveDirection.FORWARD] = {
            vector = forwardVector,
            move_func = turtle.forward
        },
        [MoveDirection.BACKWARD] = {
            vector = NewVector3(-forwardVector.x, 0, -forwardVector.z),
            move_func = turtle.back
        },
        [MoveDirection.UP] = {
            vector = Vec3Lib.up,
            move_func = turtle.up
        },
        [MoveDirection.DOWN] = {
            vector = Vec3Lib.down,
            move_func = turtle.down
        },
        [MoveDirection.RIGHT] = {
            vector = NewVector3(forwardVector.z, 0, -forwardVector.x),
            turn_direction = TurnDirection.RIGHT,
            opposite_turn_direction = TurnDirection.LEFT
        },
        [MoveDirection.LEFT] = {
            vector = NewVector3(-forwardVector.z, 0, forwardVector.x),
            turn_direction = TurnDirection.LEFT,
            opposite_turn_direction = TurnDirection.RIGHT
        }
    }

    return tools[moveDirection]
end


local function move(moveDir, steps, digObstacles)
    steps = steps or 1

    local moveTools = getMoveDirectionTools(moveDir)

    --if moveDir is to the right or left, turn in that direction and move forward recursively, then turn back
    if moveDir == MoveDirection.RIGHT or moveDir == MoveDirection.LEFT then
        turn(moveTools.turn_direction)
        move(MoveDirection.FORWARD, steps, digObstacles)
        turn(moveTools.opposite_turn_direction)
        return
    end

    --if moveDir is in any direction that needs no turning, just move in that direction
    for i = 1, steps, 1 do

        if digObstacles then
            if moveDir == MoveDirection.FORWARD then turtle.dig() end
            if moveDir == MoveDirection.UP then turtle.digUp() end
            if moveDir == MoveDirection.DOWN then turtle.digDown() end
            if moveDir == MoveDirection.BACKWARD then
                turn(TurnDirection.AROUND)
                turtle.dig()
                turn(TurnDirection.AROUND)
            end
        end

        local moveSuccess = moveTools.move_func()

        if moveSuccess then
            local newPos = Vec3Add(getTurtlePos(), moveTools.vector)
            updatePosFile(newPos)
        else
            break
        end
    end
end


local function moveGhost(moveDir, steps)
    steps = steps or 1

    local moveTools = getMoveDirectionTools(moveDir)

    local ghostPos
    for i = 1, steps, 1 do
        ghostPos = getTurtlePos()
        ghostPos = Vec3Add(ghostPos, moveTools.vector)
    end

    return ghostPos
end


local function moveAlongAxis(axis, moveValue, endFacingDirection, digObstacles)

    local directionVector = NewVector3()
    directionVector[axis] = moveValue
    directionVector = NormalizeVector3(directionVector)

    local moveDir
    if axis == Axis.Y then
        if moveValue < 0 then
            moveDir = MoveDirection.DOWN
        else
            moveDir = MoveDirection.UP
        end
    else
        moveDir = MoveDirection.FORWARD
    end

    face(directionVector)
    move(moveDir, math.abs(moveValue), digObstacles)
    face(endFacingDirection or getTurtleDir())
end


local function moveToAxisPoint(axis, targetPoint, endFacingDirection, digObstacles)
    endFacingDirection = endFacingDirection or getTurtleDir()

    local currentPointOnAxis = getTurtlePos()[axis]
    local moveValue = targetPoint - currentPointOnAxis

    moveAlongAxis(axis, moveValue, endFacingDirection, digObstacles)
end




return {
    turn = turn,
    face = face,
    move = move,
    moveGhost = moveGhost,
    moveAlongAxis = moveAlongAxis,
    moveToAxisPoint = moveToAxisPoint,
    resetPositionData = resetPositionData,
    getTurtlePos = getTurtlePos,
    getTurtleDir = getTurtleDir
}
