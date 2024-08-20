--[[
    Author: Igromanru
    Date: 19.08.2024
    Mod Name: Duplicate Items
]]

-------------------------------------
-- Hotkey to toggle the mod on/off --
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
local ToggleModKey = Key.F5
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + L
local ToggleModKeyModifiers = {}
-------------------------------------

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "DuplicateItems"
ModVersion = "1.0.1"
DebugMode = true

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
        LogInfo("Mod state changed to: " .. state)
        AFUtils.ModDisplayTextChatMessage(state)
    end)
end

RegisterKeyBind(ToggleModKey, ToggleModKeyModifiers, function()
    SetModState(not IsModEnabled)
end)

---@param Context AAbiotic_PlayerCharacter_C
---@param Inventory1 UAbiotic_InventoryComponent_C
---@param SlotIndex1 int32
---@param Inventory2 UAbiotic_InventoryComponent_C
---@param SlotIndex2 int32
local function Server_TrySwapItemsHook(Context, Inventory1, SlotIndex1, Inventory2, SlotIndex2)
    local this = Context:get()
    -- local originInventory = Inventory1:get()
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

local Server_TrySwapItemsName = "/Game/Blueprints/Characters/Abiotic_PlayerCharacter.Abiotic_PlayerCharacter_C:Server_TrySwapItems"
local Server_TrySwapItemsPreId = nil
local Server_TrySwapItemsPostId = nil
local function HookFunctionServer_TrySwapItems()
    if Server_TrySwapItemsPreId and Server_TrySwapItemsPostId then
        LogDebug("Server_TrySwapItemsFunction is already hooked, unhooking")
        UnregisterHook(Server_TrySwapItemsName, Server_TrySwapItemsPreId, Server_TrySwapItemsPostId)
    end
    Server_TrySwapItemsPreId, Server_TrySwapItemsPostId = RegisterHook(Server_TrySwapItemsName, Server_TrySwapItemsHook)
end

-- For hot reload
if DebugMode then
    HookFunctionServer_TrySwapItems()
end

RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(Context, NewPawn)
    LogDebug("[ClientRestart] called:")
    HookFunctionServer_TrySwapItems()
    LogDebug("------------------------------")
end)

LogInfo("Mod loaded successfully")
