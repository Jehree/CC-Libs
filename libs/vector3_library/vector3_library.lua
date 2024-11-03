
SumOperator = {
    PLUS = "+",
    MINUS = "-"
}

Axis = {
    X = "x",
    Y = "y",
    Z = "z"
}

local zero = {
    x = 0,
    y = 0,
    z = 0
}
local up = {
    x = 0,
    y = 1,
    z = 0
}
local down = {
    x = 0,
    y = -1,
    z = 0
}
local north = {
    x = 0,
    y = 0,
    z = 1
}
local south = {
    x = 0,
    y = 0,
    z = -1
}
local east = {
    x = 1,
    y = 0,
    z = 0
}

function NewVector3(xVal, yVal, zVal)
    xVal = xVal or 0
    yVal = yVal or 0
    zVal = zVal or 0

    return {
        x = tonumber(xVal),
        y = tonumber(yVal),
        z = tonumber(zVal)
    }
end

local west = NewVector3(-1,0,0)

local function sum(sumOperator, targetVector3, sumValue, isolateAxis)

    local newVector3 = NewVector3(targetVector3.x, targetVector3.y, targetVector3.z)

    if (isolateAxis == Axis.X or isolateAxis == Axis.Y or isolateAxis == Axis.Z) then
        if sumOperator == SumOperator.PLUS then newVector3[isolateAxis] = targetVector3[isolateAxis] + sumValue end
        if sumOperator == SumOperator.MINUS then newVector3[isolateAxis] = targetVector3[isolateAxis] - sumValue end
    else
        for k, v in pairs(targetVector3) do
            if sumOperator == SumOperator.PLUS then newVector3[k] = v + sumValue[k] end
            if sumOperator == SumOperator.MINUS then  newVector3[k] = v - sumValue[k] end
        end
    end

    return newVector3
end


function Vec3AreEqual(firstVector3, secondVector3)
    for k, v in pairs(firstVector3) do
        if secondVector3[k] ~= v then return false end
    end

    return true
end


function Vec3Add(targetVector3, additionValue, isolateAxis)
    return sum(SumOperator.PLUS, targetVector3, additionValue, isolateAxis)
end


function Vec3Subtract(targetVector3, subtractionValue, isolateAxis)
    return sum(SumOperator.MINUS, targetVector3, subtractionValue, isolateAxis)
end


function Vec3DistanceTo(originalPos, targetPos)
    return Vec3Subtract(targetPos, originalPos)
end


function Vec3Normalize(vectorToNormalize)
    local newVec3 = NewVector3(0,0,0)

    for k, v in pairs(vectorToNormalize) do
        if v < 0 then
            newVec3[k] = -1
        end

        if v == 0 then
            newVec3[k] = 0
        end

        if v > 0 then
            newVec3[k] = 1
        end
    end

    return newVec3
end


local function moveTurtleAlongAxis(moveValue, axis)
    if moveValue == 0 then return 0 end

    local distanceMoved = 0

    local function positiveMove()
        for i = 1, moveValue, 1 do
            if axis == Axis.X then

                if i == 1 then turtle.turnRight() end

                if not turtle.forward() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved + 1
                end

                if i == moveValue then turtle.turnLeft() end
            end

            if axis == Axis.Y then
                if not turtle.up() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved + 1
                end
            end

            if axis == Axis.Z then
                if not turtle.forward() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved + 1
                end
            end
        end
    end

    local function negativeMove()
        for i = 1, moveValue * -1, 1 do
            if axis == Axis.X then

                if i == 1 then turtle.turnLeft() end

                if not turtle.forward() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved - 1
                end

                if i == moveValue * -1 then turtle.turnRight() end
            end

            if axis == Axis.Y then
                if not turtle.down() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved - 1
                end
            end

            if axis == Axis.Z then
                if not turtle.back() then
                    return distanceMoved
                else
                    distanceMoved = distanceMoved - 1
                end
            end
        end
    end

    --positive direction move
    if moveValue > 0 then
        positiveMove()
    end

    --negative direction move
    if moveValue < 0 then
        negativeMove()
    end

    return distanceMoved
end


function NormalizeNumber(number)
    if number == 0 then return 0 end
    if number > 0 then return 1 end
    if number < 0 then return -1 end
end


function NormalizeVector3(vec3)
    return NewVector3(NormalizeNumber(vec3.x), NormalizeNumber(vec3.y), NormalizeNumber(vec3.z))
end


return {
    Zero = zero,
    zero = zero,
    up = up,
    down = down,
    north = north,
    south = south,
    east = east,
    west = west,
    moveTurtleAlongAxis = moveTurtleAlongAxis,
    SumOperator = SumOperator,
    Axis = Axis,
}
