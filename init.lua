-------------------------------------------------------------------------------------------------------------------------------
-- Mod expansion and additional coding by anygoodname by keanuWheeze consent.
-- This mod shall not be redistributed or modified/renamed/rebranded and published as a separate mod without keanuWheeze and anygoodname permission.
-- To use code snippets from this mod in other mods requires a consent and a proper credit note.

--[[ DISCLAIMER:

This mod is a non-commercial fan creation intended for personal use only.

By using the word "republish" I mean both republish and redistribute in this disclaimer:
You're not allowed to republish the mod without my consent or against the Nexusmods rules.
You're not allowed to republish parts of this mod code or files without consent. Either mine either other authors.
You can modify the mod code or files for your personal use only.
By modifying the mod code or files, you acknowledge I cannot support the modified mod code or files.
You're not allowed to publish your modifications to the mod code or files without my consent.
You're not allowed to publicly propose unauthorized changes to the mod code or files.
You're not allowed to use any part of the mod code or files for commercial purposes, advertising or promotion of any kind.
You can use the mod code and files to learn how to code this game mods and improve your skills.
You can use parts the code or file modifications in your creations only by my consent and on a credit note.
You're not allowed to use parts of the code or files marked as coming from other people without their consent.
You can create and publish translations of the parts of the mod that are explicitly marked as allowed to translate either in the mod description either in the mod files.
The translations must follow the Nexusmods translation publishing rules.
]]--

-- THIS MODULE DOES NOT SUPPORT TRANSLATIONS IN IT'S CURRENT SHAPE

-- Mar 7, 2024 based on the (c)keanuWheeze original script modified by (c)anygoodname by the keanuWheeze consent

-------------

local autoLoot = {
	modVer = 'v3.2.5',
	moduleVer = 'v3.2.5',
	modName = 'Autoloot',
	modAuthorName = 'keanuWheeze idea and initial coding - anygoodname expansion and additional coding',

	isUIVisible = false,
	isContinuousLooting = false,
	continuousLootingInterval = 0.33,
	continuousLootingLastAction = 0,
	continuousLootingNextAction = 0,

	settings = {
		range = 1000,
		spin = false,
		useDefaultActionKey = false,
		showDebugMonitorWindow = false,
		customTriggerKbdDelay = 0,
		customTriggerPadDelay = 0,
	},

	CPS = require("CPStyling"),
	ui = require("modules/ui"),
	config = require("modules/config"),
	logic = require("modules/logic")
}

registerInput('AutoLootMonitor', 'AutoLoot Monitor', function(isKeyDown)
	if not isKeyDown then return end
	if type(autoLoot.settings.showDebugMonitorWindow) ~= 'boolean' then autoLoot.settings.showDebugMonitorWindow = false end
	autoLoot.settings.showDebugMonitorWindow = not autoLoot.settings.showDebugMonitorWindow
	autoLoot.config.saveConfig("config/config.json", autoLoot.settings)
end)

local gameVer = 0
local isNewCetUI = false
local overlayModeWindowFlags = ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoFocusOnAppearing + ImGuiWindowFlags.NoBringToFrontOnFocus + ImGuiWindowFlags.NoCollapse
local normalModeWindowFlags = ImGuiWindowFlags.NoNavInputs + ImGuiWindowFlags.NoNavFocus + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.AlwaysAutoResize + ImGuiWindowFlags.NoFocusOnAppearing + ImGuiWindowFlags.NoBringToFrontOnFocus + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.NoScrollWithMouse + ImGuiWindowFlags.NoMouseInputs
local currentModeWindowFlags = 0
local prevTickTime = 0
local indicator = {last = 0, max = 4, chars = {'   ', '.  ', '.. ', '...'}}
local idleStr = 'Idle.'
local lootingStr = 'Looting '
function showMonitorWindow()
	ImGui.SetNextWindowPos(50, 50, ImGuiCond.FirstUseEver)
	local isStyleSet = nil
	if autoLoot.isContinuousLooting then
		ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.7, 0.14, 0.11, 0.4)
		ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)
		isStyleSet = {colorChanges = 1, varChanges = 1}
		if isNewCetUI then
			ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 2)
			ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 8, 6)
			isStyleSet.varChanges = isStyleSet.varChanges + 2
		end
		local x, y = ImGui.CalcTextSize(lootingStr..indicator.chars[indicator.max])
		ImGui.SetNextWindowSizeConstraints(x + ImGui.GetFrameHeight(), y, 900, 900)
	else
		indicator.last = 1
		ImGui.PushStyleColor(ImGuiCol.WindowBg, 0.15, 0.25, 0.204, 0.4)
		ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)
		isStyleSet = {colorChanges = 1, varChanges = 1}
		if isNewCetUI then
			ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 2)
			ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 8, 6)
			isStyleSet.varChanges = isStyleSet.varChanges + 2
		end
		local x, y = ImGui.CalcTextSize(idleStr)
		ImGui.SetNextWindowSizeConstraints(x + ImGui.GetFrameHeight(), y, 900, 900)
	end

	if ImGui.Begin('Autoloot Monitor', true, currentModeWindowFlags) then
		pcall(function()
			if autoLoot.isContinuousLooting then
				local chr = indicator.chars[indicator.last]
				if prevTickTime ~= autoLoot.logic.lastLootCompletedTime then
					prevTickTime = autoLoot.logic.lastLootCompletedTime
					indicator.last = indicator.last + 1
					if indicator.last > indicator.max then indicator.last = 1 end
					chr = indicator.chars[indicator.last]
				end
				ImGui.TextColored(0.15, 1, 1, 1, lootingStr..chr)
			else
				ImGui.TextColored(0.15, 1, 1, 1, idleStr)
			end
		end)
		ImGui.End()
	end
	if type(isStyleSet) == 'table' then
		if type(isStyleSet.colorChanges) == 'number' then ImGui.PopStyleColor(isStyleSet.colorChanges) end
		if type(isStyleSet.varChanges) == 'number' then ImGui.PopStyleVar(isStyleSet.varChanges) end
	end
end

local lastLootingActionStart = 0
local autoEventThreshold = 3
local audioEvent1, audioEvent2
local isCetKeyPressed = false
local isDefaultActionKeyPressed = false
	
registerForEvent("onInit", function()
	isNewCetUI = false
	gameVer = tonumber(Game.GetSystemRequestsHandler():GetGameVersion())
	if gameVer >= 1.61 then isNewCetUI = true end

	if not autoLoot.ui or not autoLoot.config or not autoLoot.logic then
		print(autoLoot.modName, autoLoot.modVer, 'failed to initialize as some mod files are corrupted or missing.')
		if autoLoot.ui then autoLoot.ui.isInitialized = false end
		return
	end

	currentModeWindowFlags = normalModeWindowFlags

	resetAutoLootStates()
	autoLoot.logic.resetAutoLootStates = resetAutoLootStates
	autoLoot.logic.init()
	
	if not autoLoot.logic.isInitialized then
		print(autoLoot.modName, autoLoot.modVer, 'logic.lua module failed to initialize. Possibly corrupted file.')
		if autoLoot.ui then autoLoot.ui.isInitialized = false end
		return
	end

	logic.config = autoLoot.config
	logic.settings = autoLoot.settings
	autoLoot.config.settings = autoLoot.settings

	local newSettings = logic.config.loadConfig("config/config.json", autoLoot.settings)
	if type(newSettings) == 'table' then
		for k, v in pairs(newSettings) do autoLoot.settings[k] = v end
	end

	local actionName, actionType, actionTime
	audioEvent1 = CName.new('ui_menu_tutorial_close')
	local isKBM, isPad
	local isButtonPressed, isButtonReleased = false, false

	Observe('PlayerPuppet', 'OnAction', function(this, action)
		if not autoLoot.settings.useDefaultActionKey then return end
		actionType = action:GetType(action).value
		if actionType == 'BUTTON_PRESSED' then
			isButtonPressed = true isButtonReleased = false
		elseif actionType == 'BUTTON_RELEASED' then
			isButtonPressed = false isButtonReleased = true
		else
			return
		end

		if isButtonPressed then
			actionName = Game.NameToString(action:GetName(action))
			if actionName == 'Pause' or actionName == 'OpenPauseMenu' or actionName == 'OpenMapMenu' or actionName == 'OpenCraftingMenu' or actionName == 'OpenJournalMenu' or actionName =='OpenPerksMenu' or actionName == 'OpenInventoryMenu' or actionName == 'OpenHubMenu' or actionName == 'TogglePhotoMode' or actionName == 'OpenPerksMenu' then
				autoLoot.isContinuousLooting = false return
			elseif action:IsAction(action, 'UI_Apply') then
				if not autoLoot.logic.couldStartNewLootingCycle() then
					return
				end
				if not autoLoot.isContinuousLooting then
					if autoLoot.logic.isLootDialogOnScreen then
						if autoLoot.settings.customTriggerKbdDelay > 0.6 then
							autoLoot.continuousLootingNextAction = os.clock() + autoLoot.settings.customTriggerKbdDelay
						else
							autoLoot.continuousLootingNextAction = os.clock() + 0.6
						end
					else
						if this:PlayerLastUsedPad() then
							local playerWeapon = Game.GetPlayer():GetActiveWeapon()
							if playerWeapon and playerWeapon:CanReload() then
								if autoLoot.settings.customTriggerPadDelay > 0.25 then
									autoLoot.continuousLootingNextAction = os.clock() + autoLoot.settings.customTriggerPadDelay
								else
									autoLoot.continuousLootingNextAction = os.clock() + 0.25
								end
							else
								if autoLoot.settings.customTriggerPadDelay > 0.01 then
									autoLoot.continuousLootingNextAction = os.clock() + autoLoot.settings.customTriggerPadDelay
								else
									autoLoot.continuousLootingNextAction = os.clock() + 0.01
								end
							end
						else
							if autoLoot.settings.customTriggerKbdDelay > 0 then
								autoLoot.continuousLootingNextAction = os.clock() + autoLoot.settings.customTriggerKbdDelay
							else
								autoLoot.continuousLootingNextAction = 0
							end
						end
					end
				end
				autoLoot.isContinuousLooting = true
				isDefaultActionKeyPressed = true
			end
			return
		end

		if isButtonReleased then
			if not autoLoot.isContinuousLooting then return end
			isPad = false
			isKBM = this:PlayerLastUsedKBM()
			if not isKBM then isPad = this:PlayerLastUsedPad() end
			if action:IsAction(action, 'UI_Apply') or action:IsAction(action, 'Choice1') or action:IsAction(action, 'click') or (isPad and (action:IsAction(action, 'Ping'))) then
				if
					actionName ~= 'Ping' and actionName ~= 'MeleeAttack'
						or
					(actionName == 'Ping' and (action:IsAction(action, 'UI_Apply') or action:IsAction(action, 'click') or (isPad and action:IsAction(action, 'Choice1'))))
						or
					(actionName == 'MeleeAttack' and (action:IsAction(action, 'UI_Apply') or action:IsAction(action, 'Choice1') or (isPad and action:IsAction(action, 'click'))))
				then
					if
						isKBM
							or
						(isPad and not (actionName == 'UI_DPadWeapons'))
							or
						(isPad and actionName == 'UI_DPadWeapons' and action:IsAction(action, 'UI_Apply'))
					then
						if not (
							action:IsAction(action, 'Forward')
								or
							action:IsAction(action, 'Back')
								or
							action:IsAction(action, 'Left')
								or
							action:IsAction(action, 'Right')
								or
							action:IsAction(action, 'Jump')
								or
							action:IsAction(action, 'ToggleCrouch')
							)
						then
							if not isCetKeyPressed then autoLoot.isContinuousLooting = false end
							isDefaultActionKeyPressed = false
						end
					end
				end
			end
		end
	end)

	autoLoot.ui.isInitialized = true
	autoLoot.ui.modName = autoLoot.modName
	autoLoot.ui.modVer = autoLoot.modVer
	autoLoot.logic.modName = autoLoot.modName
	autoLoot.logic.modVer = autoLoot.modVer
	print(autoLoot.modName, autoLoot.modVer, 'initialized.')
end)

local currTime = 0
local lastLootingActionState = false
local audioSystem

registerForEvent("onUpdate", function(delta)
	if autoLoot.isContinuousLooting then
		currTime = os.clock()
		if currTime > autoLoot.continuousLootingNextAction then
			if not lastLootingActionState then lastLootingActionStart = currTime end
			autoLoot.continuousLootingLastAction = currTime
			autoLoot.continuousLootingNextAction = currTime + autoLoot.continuousLootingInterval
			autoLoot.logic.lootInRange(autoLoot.settings.range, not autoLoot.settings.spin, true, true)
			lastLootingActionState = true
		end
		if autoLoot.logic.isPlayerInWorkspot then
			autoLoot.isContinuousLooting = false
			if isCetKeyPressed or isDefaultActionKeyPressed then
				lastLootingActionStart = 1
			end
			isDefaultActionKeyPressed = false
		end
	else
		if lastLootingActionState then
			if lastLootingActionStart > 0 and os.clock() - lastLootingActionStart  > autoEventThreshold then
				if not audioSystem then audioSystem = Game.GetAudioSystem() end
				if audioEvent1 then audioSystem:Play(audioEvent1) end
				if audioEvent2 then audioSystem:Play(audioEvent2) end
			end
			lastLootingActionStart = 0
			lastLootingActionState = false
		end
	end
end)

registerForEvent("onDraw", function()
	if autoLoot.isUIVisible then autoLoot.ui.draw(autoLoot) end
	if autoLoot.settings.showDebugMonitorWindow and (not logic.isInSettingsMenu()) then showMonitorWindow() end
end)

registerForEvent("onOverlayOpen", function()
	currentModeWindowFlags = overlayModeWindowFlags
    autoLoot.isUIVisible = true
end)

registerForEvent("onOverlayClose", function()
	currentModeWindowFlags = normalModeWindowFlags
    autoLoot.isUIVisible = false
end)

if GetVersion() == 'v1.21.0' then
	registerHotkey('AutoLoot', 'AutoLoot', function()
		if not autoLoot.isContinuousLooting then
			if not autoLoot.logic.couldStartNewLootingCycle() then
				return
			end
			autoLoot.logic.lootInRange(autoLoot.settings.range, not autoLoot.settings.spin, true, true)
		end
	end)
else
	registerInput('AutoLoot', 'AutoLoot', function(isKeyDown)
		isCetKeyPressed = isKeyDown
		if not autoLoot.isContinuousLooting then autoLoot.continuousLootingNextAction = 0 end
		if isKeyDown then
			if not autoLoot.logic.couldStartNewLootingCycle() then
				return
			end
			autoLoot.isContinuousLooting = true
		else
			if not isDefaultActionKeyPressed then autoLoot.isContinuousLooting = false end
		end
	end)
end

function resetAutoLootStates()
	autoLoot.isContinuousLooting = false
	lastLootingActionStart = 0
	lastLootingActionState = false
	isCetKeyPressed = false
	isDefaultActionKeyPressed = false
end

return {modName = autoLoot.modName, modVer = autoLoot.modVer, modAuthorName = autoLoot.modAuthorName}