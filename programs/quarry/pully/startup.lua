local function main()
    rednet.open("top")
    local gearshiftSide = "back"

    while true do
        local id, message = rednet.receive()

        if message == "lower_pully" then
           redstone.setOutput(gearshiftSide, true)
        end

        if message == "return_pully" then
            redstone.setOutput(gearshiftSide, false)
        end

        if message == "long_wait_message" then
            print("Turtle waiting a long time for the pully to lower... is its Y level too low? Or is storage overfilled?")
        end

        if message == "fuel_please" then
            print("Turtle needs fuel! Carefully drop fuel in the [0,0,0] corner so it'll land on the turtle. It will not continue mining until it refuels.")
        end
    end
end

main()
