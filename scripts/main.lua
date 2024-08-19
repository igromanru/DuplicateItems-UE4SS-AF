--[[
    Author: Igromanru
    Date: 16.08.2024
    Mod Name: Duplicate Items
]]

-- Hotkey to toggle the mod
local ToggleModKey = Key.L

------------------------------
-- Don't change code below --
------------------------------
local ModName = "DuplicateItems"
local DebugMode = true

local AFUtils = require("./AFUtils/AFUtils")

local function LogInfo(message)
    print(string.format("[%s] %s\n", ModName, message))
end

local function LogDebug(message)
    if DebugMode then
        LogInfo(message)
    end
end

---Logs in debug scope all relevant properties of a FAbiotic_InventoryChangeableDataStruct to console 
---@param ChangeableData FAbiotic_InventoryChangeableDataStruct
---@param Prefix string? Prefix that should be added in front of each line
local function LogInventoryChangeableDataStruct(ChangeableData, Prefix)
    if not ChangeableData then
        return
    end
    if not Prefix then
        Prefix = ""
    end

    if ChangeableData.AssetID_25_06DB7A12469849D19D5FC3BA6BEDEEAB then
        LogDebug(Prefix .. "AssetID: " .. ChangeableData.AssetID_25_06DB7A12469849D19D5FC3BA6BEDEEAB:ToString())
    end
    LogDebug(Prefix .. "CurrentItemDurability: " .. ChangeableData.CurrentItemDurability_4_24B4D0E64E496B43FB8D3CA2B9D161C8)
    LogDebug(Prefix .. "MaxItemDurability: " .. ChangeableData.MaxItemDurability_6_F5D5F0D64D4D6050CCCDE4869785012B)
    LogDebug(Prefix .. "CurrentStack: " .. ChangeableData.CurrentStack_9_D443B69044D640B0989FD8A629801A49)
    LogDebug(Prefix .. "CurrentAmmoInMagazine: " .. ChangeableData.CurrentAmmoInMagazine_12_D68C190F4B2FA78A4B1D57835B95C53D)
    LogDebug(Prefix .. "LiquidLevel: " .. ChangeableData.LiquidLevel_46_D6414A6E49082BC020AADC89CC29E35A)
    LogDebug(Prefix .. "CurrentLiquid (enum): " .. ChangeableData.CurrentLiquid_19_3E1652F448223AAE5F405FB510838109)
end

local function ModDisplayTextChatMessage(Message)
    local prefix = string.format("[%s]", ModName)
    LogDebug("ModDisplayTextChatMessage Prefix: " .. prefix .. ", Message: " .. Message)
    AFUtils.DisplayTextChatMessage(Message, prefix)
end

---@param Inventory UAbiotic_InventoryComponent_C
---@param SlotIndex integer
---@return integer CurrentStack Bigger than 0 is valid, otherwise failed
local function GetItemSlotCurrentStack(Inventory, SlotIndex)
    LogDebug("GetItemSlotCurrentStack: SlotIndex: " .. SlotIndex)
    local itemSlot = AFUtils.GetInventoryItemSlot(Inventory, SlotIndex)
    if itemSlot and itemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313 then
        local currentStack = itemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentStack_9_D443B69044D640B0989FD8A629801A49
        LogDebug("GetItemSlotCurrentStack: CurrentStack: " .. currentStack)
        return currentStack
    else
        LogDebug("GetItemSlotCurrentStack: Couldn't find an item in slot: " .. SlotIndex)
    end

    return 0
end

LogInfo("Starting mod initialization")

local IsModEnabled = false

local function SetModState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        IsModEnabled = Enable
        local state = "Disabled"
        if IsModEnabled then
            state = "Enabled"
        end
        LogDebug("Mod state changed to: " .. state)
        ModDisplayTextChatMessage(state)
    end)
end

RegisterKeyBind(ToggleModKey, function()
    SetModState(not IsModEnabled)
end)

---@param Context AAbiotic_PlayerCharacter_C
---@param Inventory1 UAbiotic_InventoryComponent_C
---@param SlotIndex1 int32
---@param Inventory2 UAbiotic_InventoryComponent_C
---@param SlotIndex2 int32
function Server_TrySwapItemsHook(Context, Inventory1, SlotIndex1, Inventory2, SlotIndex2)
    local this = Context:get()
    local originInventory = Inventory1:get()
    local originSlotIndex = SlotIndex1:get()
    local targetInventory = Inventory2:get()
    local targetSlotIndex = SlotIndex2:get()
    
    LogDebug("[Server_TrySwapItems] called:")
    LogDebug("SlotIndex1: " .. originSlotIndex)
    LogDebug("SlotIndex2: " .. targetSlotIndex)

    if IsModEnabled then
        local myPlayer = AFUtils.GetMyPlayer()
        -- Check if it's the local player
        if myPlayer and this:GetAddress() == myPlayer:GetAddress() then
            local myPlayerController = AFUtils.GetMyPlayerController()
            if myPlayerController then
                local currentItemStack = GetItemSlotCurrentStack(targetInventory, targetSlotIndex)
                if not currentItemStack or currentItemStack <= 0 then
                    currentItemStack = 1
                end
                myPlayerController:Server_AddToItemStack(targetInventory, targetSlotIndex, currentItemStack)
            end
        end
    end
    LogDebug("------------------------------")
end

RegisterHook("/Game/Blueprints/Characters/Abiotic_PlayerCharacter.Abiotic_PlayerCharacter_C:Server_TrySwapItems", Server_TrySwapItemsHook)

LogInfo("Mod loaded successfully")