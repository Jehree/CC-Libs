local CommandAttributes = {
    FINAL_COMMAND = 0,
    DO_NOT_CLEAR_CONSOLE = 1,
}

local commands = {}
--I should change the bound functions so that they can be bound to specific commands, not every single one globally
local boundFunctions = {} --these funcs will be called after every single command is ran

local isHosting = false
local hostId
local clientId


local function wirelessSetup(hostIdNum, clientIdNum)
    peripheral.find("modem", rednet.open)
    hostId = hostIdNum
    clientId = clientIdNum
end


function cleary()
    term.clear()
    term.setCursorPos(1,1)

    if not isHosting then return end

    if os.getComputerID() == hostId then
        rednet.send(clientId, "clear")
    end
end

function printy(text)

    print(text)

    if not isHosting then return end

    if os.getComputerID() == hostId then
        rednet.send(clientId, "print;;;"..(text or "nil"))
    end
end

function writey(text)
    write(text)

    if not isHosting then return end

    if os.getComputerID() == hostId then
        rednet.send(clientId, "write;;;"..(text or "nil"))
    end
end

function readie()
    local myId = os.getComputerID()

    if not isHosting and myId ~= clientId then
        return read()
    end

    if myId == hostId then
        rednet.send(clientId, "read")

        while true do
            local id, input = rednet.receive()
            if id == clientId then
                return input, id
            end
        end
    end

    if myId == clientId then
        local input = read()
        print(input)
        rednet.send(hostId, input)
    end
end


local function fancyMonitorWrite(monitor, text, textColor, bgColor, scale, cursorPos)
    monitor.setCursorPos(cursorPos[1] or 1, cursorPos[2] or 1)

    local returnTextColor = monitor.getTextColor()
    local returnBgColor = monitor.getBackgroundColor()
    local returnScale = monitor.getTextScale()

    textColor = textColor or returnTextColor
    bgColor = bgColor or returnBgColor
    scale = scale or returnScale

    monitor.setTextColor(textColor)
    --monitor.setBackgroundColor(bgColor)
    monitor.setTextScale(scale)

    monitor.write(text)

    monitor.setTextColor(returnTextColor)
    --monitor.setBackgroundColor(returnBgColor)
    monitor.setTextScale(returnScale)
end


--can prob make this func global, maybe with a rename to CmdLibCommandExists or similar
local function commandExists(input)
    for k, v in pairs(commands) do
        if k == input then return true end
    end

    return false
end


local function handleCommand(input, commandInstructionText, finalCommandText)
    if not commandExists(input) then
        cleary()
        printy("Invalid command: "..input)
        writey(commandInstructionText)
    else
        local commandAttribute = commands[input].func(commands[input].defaultArguments)

        for _, v in ipairs(boundFunctions) do
            v.func(v.defaultArguments)
        end

        if commandAttribute == CommandAttributes.FINAL_COMMAND then
            cleary()
            printy(finalCommandText)
            return CommandAttributes.FINAL_COMMAND
        end

        if commandAttribute ~= CommandAttributes.DO_NOT_CLEAR_CONSOLE then
            cleary()
        end

        writey(commandInstructionText)
    end
end


local function listenForWirelessCommands()
    peripheral.find("modem", rednet.open)

    while true do
        print("host waiting...")

        local input, id = readie()

        if id == clientId then
            local commandAttribute = handleCommand(input, "remote: ", "Wireless mode disabled!")

            if commandAttribute == CommandAttributes.FINAL_COMMAND then
                break
            end
        end
    end

    isHosting = false
end


local function beginHosting()
    if not hostId or not clientId then
        cleary()
        printy("Wireless setup needed! run wirelessSetup function before command listening begins.")
        return CommandAttributes.DO_NOT_CLEAR_CONSOLE
    end

    isHosting = true

    print("Wireless mode enabled!")
    listenForWirelessCommands()
end


local function initBaseCommands()

    local function help()
        cleary()

        printy("Available commands: ")
        for k, v in pairs(commands) do
            printy(k.." : "..v.helpMessage)
        end

        return CommandAttributes.DO_NOT_CLEAR_CONSOLE
    end

    local baseCommands = {
        exit = {
            helpMessage = "Exits the program",
            func = function () return CommandAttributes.FINAL_COMMAND end,
            defaultArguments = nil
        },

        help = {
            helpMessage = "Lists all commands and their help messages",
            func = help,
            defaultArguments = nil
        },

        clear = {
            helpMessage = "Clears the console",
            func = cleary,
            defaultArguments = nil
        },

        wireless = {
            helpMessage = "Switches listen mode to wireless",
            func = beginHosting,
            defaultArguments = nil
        }
    }

    for k, v in pairs(baseCommands) do
        commands[k] = v
    end
end


local function createCommand(commandName, helpMsg, functionCallable, defaultArguments)
    commands[commandName] = {
        helpMessage = helpMsg,
        func = functionCallable,
        defaultArguments = defaultArguments
    }
end


--I should change the bound functions so that they can be bound to specific commands, not every single one globally
local function addBoundFunction(functionCallable, defaultArguments)
    table.insert(
        boundFunctions,
        {
            func = functionCallable,
            defaultArguments = defaultArguments
        }
    )
end


local function listenForCommands(commandInstructionText, finalCommandText)
    writey(commandInstructionText)

    initBaseCommands()

    while true do
        local input = readie()

        local commandAttribute = handleCommand(input, commandInstructionText, finalCommandText)

        if commandAttribute == CommandAttributes.FINAL_COMMAND then break end
    end
end


--it may be better to make the client part of the wireless features it's own separate program
--that may be easier to read and a little cleaner, while also making the client program even lighter
local function enableWirelessSending()
    peripheral.find("modem", rednet.open)
    write("remote: ")

    local commandKeys = {
        write = writey,
        print = printy,
        read = readie,
        clear = cleary
    }

    --running readie() directly from the client like this only works if the host is already waiting for a read
    --doing it here is important so a client reboot doesn't break the connection
    readie()

    while true do
        local id, message = rednet.receive()

        local parsedMessage = StringSplit(message, ";;;")
        local cmdKey = parsedMessage[1]
        local arg = parsedMessage[2]
        if commandKeys[cmdKey] then commandKeys[cmdKey](arg) end
    end
end


return {
    CommandAttributes = CommandAttributes,
    listenForCommands = listenForCommands,
    createCommand = createCommand,
    addBoundFunction = addBoundFunction,
    clr = cleary,
    pr = printy,
    wr = writey,
    rd = readie,
    fancyMonitorWrite = fancyMonitorWrite,
    enableWirelessSending = enableWirelessSending,
    wirelessSetup = wirelessSetup,
    isHosting = function () return isHosting end,
    hostId = function () return hostId end,
    clientId = function () return clientId end,
}
