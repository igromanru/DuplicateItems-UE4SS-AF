--[[
    Author: Igromanru
    Date: 19.08.2024
    Mod Name: Duplicate Items
]]

-------------------------------------
---------- Configurations -----------
-------------------------------------
-- Hotkey to toggle the mod on/off --
-- Possible keys: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/key.md
ToggleModKey = Key.F5
-- See ModifierKey: https://github.com/UE4SS-RE/RE-UE4SS/blob/main/docs/lua-api/table-definitions/modifierkey.md
-- ModifierKeys can be combined. e.g.: {ModifierKey.CONTROL, ModifierKey.ALT} = CTRL + ALT + L
ToggleModKeyModifiers = {}
-------------------------------------
WhileHoldingKeypadHacker = true

------------------------------
-- Don't change code below --
------------------------------
local AFUtils = require("AFUtils.AFUtils")

ModName = "DuplicateItems"
ModVersion = "1.1.3"
DebugMode = true
IsModEnabled = false

LogInfo("Starting mod initialization")

local function SetModState(Enable)
    ExecuteInGameThread(function()
        Enable = Enable or false
        IsModEnabled = Enable
        local state = "Disabled"
        local warningColor =  AFUtils.CriticalityLevels.Red
        if IsModEnabled then
            state = "Enabled"
            warningColor =  AFUtils.CriticalityLevels.Green
        end
        local message = "Duplicate Items " .. state
        LogInfo(message)
        AFUtils.ClientDisplayWarningMessage(message, warningColor)
    end)
end

---Returns false if should be filtered out
---@param PlayerCharacter AAbiotic_PlayerCharacter_C
---@param TargetInventory UAbiotic_InventoryComponent_C
---@return boolean
local function PlayerEquipmentAndHotbarFilter(PlayerCharacter, TargetInventory)
    local TargetInventoryAddress = TargetInventory:GetAddress()
    if (IsValid(PlayerCharacter.CharacterEquipSlotInventory) and PlayerCharacter.CharacterEquipSlotInventory:GetAddress() == TargetInventoryAddress)
        or (IsValid(PlayerCharacter.CharacterHotbarInventory) and PlayerCharacter.CharacterHotbarInventory:GetAddress() == TargetInventoryAddress) then
        return false
    end
    return true
end

local function Server_TrySwapItemsHook(Context, Inventory1, SlotIndex1, Inventory2, SlotIndex2)
    local playerCharacter = Context:get() ---@type AAbiotic_PlayerCharacter_C
    -- local originInventory = Inventory1:get() ---@type UAbiotic_InventoryComponent_C
    -- local originSlotIndex = SlotIndex1:get() ---@type integer
    local targetInventory = Inventory2:get() ---@type UAbiotic_InventoryComponent_C
    local targetSlotIndex = SlotIndex2:get() ---@type integer

    LogDebug("[Server_TrySwapItems] called:")
    -- LogDebug("SlotIndex1: " .. originSlotIndex)
    LogDebug("SlotIndex2: " .. targetSlotIndex)
    
    if (IsModEnabled or (WhileHoldingKeypadHacker and AFUtils.IsHoldingKeypadHacker(playerCharacter))) and IsValid(targetInventory) then
        if PlayerEquipmentAndHotbarFilter(playerCharacter, targetInventory) then
            local playerController = AFUtils.GetPlayerController(playerCharacter)
            if IsValid(playerController) then
                local itemSlot = AFUtils.GetInventoryItemSlot(targetInventory, targetSlotIndex)
                if itemSlot then
                    local currentItemStack = itemSlot.ChangeableData_12_2B90E1F74F648135579D39A49F5A2313.CurrentStack_9_D443B69044D640B0989FD8A629801A49
                    if not currentItemStack or currentItemStack < 1 then
                        currentItemStack = 1
                    end
                    playerController:Server_AddToItemStack(targetInventory, targetSlotIndex, currentItemStack)
                end
            end
        end
    end
    LogDebug("------------------------------")
end

RegisterKeyBind(ToggleModKey, ToggleModKeyModifiers, function()
    SetModState(not IsModEnabled)
end)

ExecuteInGameThread(function()
    LogInfo("Initializing hooks")
    LoadAsset("/Game/Blueprints/Characters/Abiotic_PlayerCharacter.Abiotic_PlayerCharacter_C")
    RegisterHook("/Game/Blueprints/Characters/Abiotic_PlayerCharacter.Abiotic_PlayerCharacter_C:Server_TrySwapItems", Server_TrySwapItemsHook)
    LogInfo("Hooks initialized")
end)

LogInfo("Mod loaded successfully")
