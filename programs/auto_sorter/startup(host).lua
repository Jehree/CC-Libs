--rename to startup.lua
package.path = package.path .. ";../?.lua"
CmdLib = require("libraries.command_line_library.command_line_library")
require("libraries.misc_utils.utils")

local monitor = peripheral.wrap("monitor_0")

local drawerControllerName = "storagedrawers:controller_3"
local drawerController = peripheral.wrap(drawerControllerName)

local itemRequestChestName = "ironchests:iron_chest_0"
local itemRequestChest = peripheral.wrap(itemRequestChestName)

local pullChuteName = "create:chute_10"
local pullChute = peripheral.wrap(pullChuteName)

local vaultName = "create:item_vault_2"
local vault = peripheral.wrap(vaultName)

local unstackableChute1Name = "create:chute_5"
local unstackableChute1 = peripheral.wrap(unstackableChute1Name)

local unstackableChute2Name = "create:chute_6"
local unstackableChute2 = peripheral.wrap(unstackableChute2Name)

local unstackableChute3Name = "create:chute_7"
local unstackableChute3 = peripheral.wrap(unstackableChute3Name)

local unstackableChuteNames = {
    unstackableChute1Name,
    unstackableChute2Name,
    unstackableChute3Name
}


local function main()
    UpdateMonitor()

    CmdLib.addBoundFunction(UpdateMonitor)
    CmdLib.wirelessSetup(os.getComputerID(), 3)

    CmdLib.createCommand("test", "", Test)
    CmdLib.createCommand("sort", "Sort items in vault to drawers and unstackable chests", Sort, {inventory = vault})
    CmdLib.createCommand("deposit", "Deposit items in itemRequestChest into the storage system", Sort, {inventory = itemRequestChest, overflowName = vaultName})
    CmdLib.createCommand("full_search", "Get items contained in vault and drawers by name", SearchForItem)
    CmdLib.createCommand("search", "Get items contained in vault and drawers by name, faster than full search but has less info", FastItemSearch)
    CmdLib.createCommand("give", "Request an item stored in system to be sent to request chest", RequestItemFast, itemRequestChestName)
    CmdLib.createCommand("pull", "Request an item stored system to be sent to out of compact machine ", RequestItemFast, pullChuteName)
    CmdLib.createCommand("request_d", "Request an item stored in Storage Drawers by slots", RequestItemSlots, drawerController)
    CmdLib.createCommand("request_v", "Request an item stored in Vault by slots", RequestItemSlots, vault)
    CmdLib.createCommand("refresh", "Refreshes vault status display", UpdateMonitor)

    CmdLib.pr("Blood Orange Storage System Launched!")

    CmdLib.listenForCommands("Enter command: ", "Storage System Terminated")
end


function Test()
    CmdLib.pr("This is a test")
    return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
end


function UpdateMonitor()
    monitor.clear()

    local vaultFullness = GetArrayLength(vault.list()) / vault.size()
    local fullCharacterAmount = 27
    local vaultFullnesCharacterAmount = math.ceil(fullCharacterAmount * vaultFullness)

    local statusBar = ""
    for i = 1, fullCharacterAmount, 1 do
        if i <= vaultFullnesCharacterAmount then
            statusBar = statusBar.."="
        else
            statusBar = statusBar.." "
        end
    end

    local barColor = colors.green
    if vaultFullness > 0.5 then barColor = colors.orange end
    if vaultFullness > 0.8 then barColor = colors.red end

    CmdLib.fancyMonitorWrite(monitor, "        VAULT STATUS:", colors.yellow, nil, nil, {1,1})
    CmdLib.fancyMonitorWrite(monitor, "|                           |", barColor, nil, nil, {1,2})
    CmdLib.fancyMonitorWrite(monitor, "|"..statusBar.."|", barColor, nil, nil, {1,3})
    CmdLib.fancyMonitorWrite(monitor, "|                           |", barColor, nil, nil, {1,4})
    CmdLib.fancyMonitorWrite(monitor, "                     "..GetArrayLength(vault.list()).."/"..vault.size(), colors.yellow, nil, nil, {1,5})
end


function RequestItemSlots(inventory)
    CmdLib.pr("Enter slots you would like to request.")
    CmdLib.pr("If multiple, separate them with ; (no spaces).")
    CmdLib.pr("If more than one stack is needed, enter the slot multiple times.")
    CmdLib.wr("Slots: ")
    local slotsInput = CmdLib.rd()
    local slotsList = StringSplit(slotsInput, ";", true)

    for k, slot in ipairs(slotsList) do
        inventory.pushItems(itemRequestChestName, slot, 64)
    end

    CmdLib.clr()
    CmdLib.pr("Request complete!")
    return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
end


function RequestItemFast(sendToInventoryName)
    CmdLib.pr("Enter part or whole of an item id")
    CmdLib.wr("->: ")
    local itemNameSnippet = CmdLib.rd()

    local vaultItems = vault.list()
    local drawerItems = drawerController.list()

    local foundItems = {}
    for slot, item in pairs(vaultItems) do
        if StringIncludesString(item.name, itemNameSnippet) then
            table.insert(foundItems, {name = item.name, slot = slot, inventory = vault})
        end
    end

    for slot, item in pairs(drawerItems) do
        if StringIncludesString(item.name, itemNameSnippet) then
            table.insert(foundItems, {name = item.name, slot = slot, inventory = drawerController})
        end
    end

    if not foundItems[1] then
        CmdLib.clr()
        CmdLib.pr("No items found including: "..itemNameSnippet)
        return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
    end

    for i = GetArrayLength(foundItems), 1, -1 do
        local nameToProcess = StringSplit(foundItems[i].name, ":")[2]
        local nameToProcessLen = string.len(nameToProcess)

        for k, item in ipairs(foundItems) do
            local comparisonName = StringSplit(item.name, ":")[2]
            local comparisonNameLen = string.len(comparisonName)

            if nameToProcessLen > comparisonNameLen then
                table.remove(foundItems, i)
                break
            end
        end
    end

    ---[[
    CmdLib.pr("Only up to one stack can be given at a time")
    CmdLib.pr("If many stacks are needed, use the request_d or request_v command")
    CmdLib.wr("Amount (full stack if blank): ")
    local amount = readie()
    amount = tonumber(amount)

    local itemsTransferedCount = foundItems[1].inventory.pushItems(sendToInventoryName, foundItems[1].slot, amount or 64)
    CmdLib.clr()
    CmdLib.pr(itemsTransferedCount.." "..foundItems[1].name.."'s transferred!")
    return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
    --]]
end


function SearchForItem()
    CmdLib.clr()

    CmdLib.pr("Enter part or whole of an item id")
    CmdLib.wr("->: ")
    local itemNameSnippet = CmdLib.rd() or ":"

    CmdLib.pr("Searching...")

    local foundItems = GetAllMatchingItems(itemNameSnippet)

    CmdLib.clr()

    if GetArrayLength(foundItems) == 0 then
        CmdLib.clr()
        CmdLib.pr("No items found by the name: "..itemNameSnippet)
        return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
    end

    local scrollIndex = 1
    CmdLib.pr("Press 'Enter' to exit search list")

    term.setTextColor(colors.purple)
    CmdLib.pr("LIST ITEM "..scrollIndex..":")
    term.setTextColor(colors.orange)
    CmdLib.pr("Inventory: "..foundItems[scrollIndex].inventory)
    CmdLib.pr("Slot: "..foundItems[scrollIndex].slot)
    CmdLib.pr("Display Name: "..foundItems[scrollIndex].display_name)
    CmdLib.pr("Name: "..foundItems[scrollIndex].name)
    CmdLib.pr("Count: "..foundItems[scrollIndex].count)
    CmdLib.pr(" ")
    term.setTextColor(colors.white)

    while true do
        local eventData = {os.pullEvent()}
        local event = eventData[1]

        if event == "mouse_scroll" then
            local dir = eventData[2]

            if foundItems[scrollIndex + dir] then
                scrollIndex = scrollIndex + dir

                if scrollIndex == 1 then
                    CmdLib.pr("Press 'Enter' to exit search list")
                end

                term.setTextColor(colors.purple)
                CmdLib.pr("LIST ITEM "..scrollIndex..":")
                term.setTextColor(colors.orange)
                CmdLib.pr("Inventory: "..foundItems[scrollIndex].inventory)
                CmdLib.pr("Slot: "..foundItems[scrollIndex].slot)
                CmdLib.pr("Display Name: "..foundItems[scrollIndex].display_name)
                CmdLib.pr("Name: "..foundItems[scrollIndex].name)
                CmdLib.pr("Count: "..foundItems[scrollIndex].count)
                term.setTextColor(colors.white)

                if scrollIndex == GetArrayLength(foundItems) then
                    --CmdLib.pr("Press 'Enter' to exit search list")
                end
                CmdLib.pr(" ")
            end

        elseif event == "key" then
            local key = eventData[2]

            if key == 257 then
                CmdLib.clr()
                CmdLib.pr("Exiting search!")
                return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
            end
        end
    end
end


function FastItemSearch()
    cleary()

    printy("Enter part or whole of an item id")
    writey("->: ")
    local input = readie() or ":"

    local vaultItems = vault.list()
    local drawerItems = drawerController.list()
    local processedSearchResults = {}

    local function processResults(list, dOrV)
        for slot, item in pairs(list) do
            if StringIncludesString(item.name, input) then
                local result = item.name..", cnt: "..item.count..", sl: "..slot..", "..dOrV
                local result = {
                    "name: "..item.name..", count: "..item.count,
                    "inventory: "..dOrV..", ".."slot: "..slot
                }
                table.insert(processedSearchResults, result)
            end
        end
    end

    processResults(vaultItems, "vault")
    processResults(drawerItems, "drawer")

    local searchResultLength = GetArrayLength(processedSearchResults)

    if searchResultLength <= 0 then
        cleary()
        printy("no items found by the search: "..input)
        return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
    end

    local pageSize = 5
    if CmdLib.isHosting() then pageSize = 3 end
    local currentPage = 1
    local numberOfPages = math.ceil(searchResultLength / pageSize)
    local exitSearch = false

    while true do
        cleary()
        for i = pageSize * (currentPage - 1) + 1, pageSize * currentPage, 1 do

            local result = processedSearchResults[i]
            if result then
                printy(i..":")
                printy(result[1])
                printy(result[2])
            end

            local lastPageKey = pageSize * currentPage
            if i == lastPageKey then
                printy(" ")
                writey("Enter f, b or exit: ")
                local controlInput = readie()


                if controlInput == "f" or controlInput == "" then
                    currentPage = currentPage +1

                    if currentPage > numberOfPages then currentPage = numberOfPages end
                    break
                end
                if controlInput == "b" then
                    currentPage = currentPage - 1
                    if currentPage <= 0 then currentPage = 1 end
                    break
                end
                if controlInput == "exit" then
                    exitSearch = true
                    break
                end
            end
        end
        if exitSearch then break end
    end
end


function GetAllMatchingItems(itemNameSnippet)
    local foundItemsInVault = GetMatchingItemsInInventory(itemNameSnippet, vault, "Vault", vaultName)
    local foundItemsInDrawers = GetMatchingItemsInInventory(itemNameSnippet, drawerController, "Storage Drawers", drawerControllerName)
    local foundItems = {}
    for k,v in pairs(foundItemsInVault) do foundItems[k] = v end
    for k,v in pairs(foundItemsInDrawers) do foundItems[k + GetArrayLength(foundItemsInVault)] = v end

    return foundItems
end


function GetMatchingItemsInInventory(itemNameSnippet, inventory, inventoryDisplayName, inventoryNetId)
    local items = inventory.list()
    local foundItems = {}

    for slot,v in pairs(items) do
        local itemDetails = inventory.getItemDetail(slot)

        if StringIncludesString(v.displayName, itemNameSnippet) or StringIncludesString(v.name, itemNameSnippet) then

            table.insert(foundItems, {
                slot = slot,
                display_name = itemDetails.displayName,
                name = itemDetails.name,
                count = itemDetails.count,
                inventory = inventoryDisplayName,
                inventory_network_id = inventoryNetId,
            })
        end
    end

    return foundItems
end


function Sort(args)
    CmdLib.clr()

    local inventory = args.inventory
    local overflowInventoryName = args.overflowName

    for slot, _ in pairs(inventory.list()) do
        local item = inventory.getItemDetail(slot)

        local printName = item.displayName
        if printName == "" then printName = item.name end

        --try to push to drawers
        local pushedItemCount = inventory.pushItems(drawerControllerName, slot)
        if pushedItemCount > 0 then CmdLib.pr(printName.." -> drawer controller ") end

        --if max stack size is 1 and we didn't push it to a drawer, try and push it to unstackable chutes
        if pushedItemCount == 0 and item.maxCount == 1 then
            pushedItemCount = PushItemToUnstackableChests(inventory, slot, printName)
        end

        --if there are any items left that didn't get pushed, and an overflow was provided, push them to the overflow
        if overflowInventoryName and pushedItemCount < item.count then
            pushedItemCount = inventory.pushItems(overflowInventoryName, slot)
            CmdLib.pr(printName.." -> "..overflowInventoryName)
        end
    end

    CmdLib.pr("Sort complete!")
    return CmdLib.CommandAttributes.DO_NOT_CLEAR_CONSOLE
end


function PushItemToUnstackableChests(fromInventory, fromSlot, printName)
    local pushedItemCount = 0

    for k, chuteName in ipairs(unstackableChuteNames) do

        pushedItemCount = fromInventory.pushItems(chuteName, fromSlot)
        sleep(0.3) --delay so chute has time to drop item in chest

        if pushedItemCount > 0 then
            CmdLib.pr(printName.." -> unstackable chest "..k)
            break
        end
    end

    return pushedItemCount
end



main()
