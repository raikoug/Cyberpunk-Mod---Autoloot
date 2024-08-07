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
-- Uses (c)psiberx code snippets and libraries on his license.

-------------

logic = {
			modVer = 'v3.2.5',
			moduleVer = 'v3.2.5',
			modName = 'Autoloot',
			modAuthorName = 'keanuWheeze and anygoodname',
			lastLootCompletedTime = 0,
			isPlayerInWorkspot = false, isLootDialogOnScreen = false, isAnyDialogOnScreen = false, isAnyOtherInteractonOnScreen = false, cooldown = 0,
			isInitialized = false,
		}

-- prerequisites:

local Ref = require('lib/Ref')
if not Ref then return end
local journalMappinExtractor = require('lib/journalMappinExtractor')
if not journalMappinExtractor then return end

local lastLootingController, isLootDialogOnScreen, isAnyDialogOnScreen, isAnyOtherInteractonOnScreen, cooldown
local lastPhoneMessagePopupGameController, lastLoadingScreenProgressBarController, lastTutorialMainController = nil, nil, nil
local lastInteractionUIBase = nil
local lastCursorDeviceGameController, lastTerminalInteractionActive = nil, false
local objectMappins = {}
local objectMappinsCount = 0
local worldMappins = {}
local allJournalQuestEntries = {}
local customLootMappins = {}
local protectedSpecialItems = {}
local collectedPoiMappins = nil
local lastDialogWidgetGameController = nil
local isGameV2 = false
local protectKeyCards = true
local questsSystem = nil

local lootResult = {
	generalFailure = -4,
	allItemsFailed = -3,
	notLootObject = -2,
	protectedObject = -1,
	nothingToLoot = 0,
	partialLoot = 1,
	allLooted = 2
	}

function logic.init()
	protectedSpecialItems = {
		{id = TweakDBID.new("Items.Q115_Afterlife_Netrunner"), position = Vector4.new(-1448.006, 999.9223, 16.980827, 1)},
		{id = nil, position = Vector4.new(-1741.0364, -2352.3066, 32.136505, 1)},
		{id = nil, position = Vector4.new(-2034.3328, -2735.4219, 36.66288, 1)},
		{id = nil, position = Vector4.new(-1394.0176, -2036.0061, 75.7336, 1)},
		{id = nil, position = Vector4.new(-1434.1599, -2030.45, 74.83998, 1)},
		{id = nil, position = Vector4.new(-1397.3597, -2014.2797, 72.139984, 1)},
		{id = nil, position = Vector4.new(-1417.3597, -2081.31, 72.14998, 1)},
		{id = nil, position = Vector4.new(-1372.9598, -1932.09, 71.11998, 1)},
		{id = nil, position = Vector4.new(-2412.8733, -2662.6848, 13.127945, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2413.4795, -2661.944, 12.942177, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2413.816, -2661.3318, 12.942177, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2413.4268, -2661.377, 13.230896, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2413.1953, -2661.8281, 13.237434, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2417.722, -2659.966, 13.014374, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2418.1, -2659.8289, 13.286064, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2420.0388, -2664.5303, 11.776367, 1), factName = "q303_05_safehouse_majesty_picked_up"},
		{id = nil, position = Vector4.new(-2417.5742, -2659.9058, 12.392654, 1), factName = "q303_05_safehouse_majesty_picked_up"},
	}
	logic.resetVariables()
	logic.setObservers()
	if journalMappinExtractor then journalMappinExtractor.init() end
	logic.isInitialized = true
end

function logic.resetVariables()
	lastLootingController = nil
	logic.isPlayerInWorkspot = false
	logic.isLootDialogOnScreen = false
	logic.isAnyDialogOnScreen = false
	logic.isAnyOtherInteractonOnScreen = false
	logic.cooldown = 0
	objectMappins = {}
	objectMappinsCount = 0
	allJournalQuestEntries = {}
	customLootMappins = {}
	collectedPoiMappins = nil
	lastCursorDeviceGameController = nil
	lastTerminalInteractionActive = false
end

function logic.isInSettingsMenu()
	if not GetPlayer then return end
	result, blackboardSystem = pcall(function() return Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UI_System) end)
	if not result then return true end
	if not IsDefinedS(blackboardSystem) then return true end
	if not blackboardSystem:GetBool(Game.GetAllBlackboardDefs().UI_System.IsInMenu) then return end
	return logic.isMenuScenario_Settings
end

function logic.setObservers()

	isGameV2 = tonumber(Game.GetSystemRequestsHandler():GetGameVersion()) >= 2

	ObserveAfter('inkMenuScenario', 'SwitchToScenario', function(this, name)
		logic.isMenuScenario_Settings = false
		if name.value == 'MenuScenario_Settings' then logic.isMenuScenario_Settings = true end
	end)

	if isGameV2 then
		ObserveAfter("WorldMappinsContainerController", "CreateMappinUIProfile", function(this, mappin, mappinVariant, customData);
			local shouldRegisterMappin = mappin:IsQuestMappin()
				or mappin:IsQuestImportant()
				or mappinVariant == gamedataMappinVariant.FocusClueVariant
				or mappinVariant == gamedataMappinVariant.HiddenStashVariant
				or mappinVariant == gamedataMappinVariant.ImportantInteractionVariant
				or mappinVariant == gamedataMappinVariant.MinorActivityVariant
				or mappinVariant == gamedataMappinVariant.Zzz07_PlayerStashVariant
				or mappinVariant == gamedataMappinVariant.Zzz08_WardrobeVariant
				or mappinVariant == gamedataMappinVariant.Zzz12_WorldEncounterVariant
				or mappinVariant == gamedataMappinVariant.Zzz16_RelicDeviceBasicVariant
				or mappinVariant == gamedataMappinVariant.Zzz16_RelicDeviceSpecialVariant
			
			if not shouldRegisterMappin then return end;
			local position = mappin:GetWorldPosition();
			local mappinId = tostring(position.x)..tostring(position.y)..tostring(position.z);
			if not collectedPoiMappins then collectedPoiMappins = {} end
			collectedPoiMappins[mappinId] = {mappin = mappin, position = position, mappinVariant = mappinVariant};
		end);
	end

	Observe('LoadingScreenProgressBarController', 'SetProgress', function(self) if IsDefinedS(self) then lastLoadingScreenProgressBarController = Ref.Weak(self) end end)
	Observe('TutorialMainController', 'OnInitialize', function(self) if IsDefinedS(self) then lastTutorialMainController = Ref.Weak(self) end end)
	Observe('TutorialMainController', 'StartTutorial', function(self) if IsDefinedS(self) then lastTutorialMainController = Ref.Weak(self) end end)
	Observe('TutorialMainController', 'UpdateTutorialStep', function(self) if IsDefinedS(self) then lastTutorialMainController = Ref.Weak(self) end end)

	if modAutolootRedsHelper then
		local isSupportedVersion = false
		if type(modAutolootRedsHelper.GetVersion) == 'function' then
			local helperVerStr = modAutolootRedsHelper.GetVersion()
			if type(helperVerStr) == 'string' then
				local helperVer = tonumber((helperVerStr:gsub('^(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- based on psiberx code
					return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
				end)))
				if helperVer >= 3.0117 then
					logic.shouldUseRedsHelper = true
					isSupportedVersion = true
					print(logic.modName, logic.modVer, 'Redscript helper plug-in found:', helperVerStr)
				else
					print(logic.modName, logic.modVer, 'Outdated redscript helper plug-in version found:', helperVerStr, 'The plugin will not be used.')
				end
			else
				print(logic.modName, logic.modVer, 'Unknown redscript helper plug-in found. The plugin will not be used.')
			end
		else
			print(logic.modName, logic.modVer, 'Outdated redscript helper plug-in found. The plugin will not be used.')
		end
		if not isSupportedVersion then
			local cetVer = tonumber((GetVersion():gsub('^v(%d+)%.(%d+)%.(%d+)(.*)', function(major, minor, patch, wip) -- (c)psiberx
				return ('%d.%02d%02d%d'):format(major, minor, patch, (wip == '' and 0 or 1))
			end)))
			if cetVer >= 1.21 then print(logic.modName, logic.modVer, 'The redscript helper plug-in is no longer needed so you can ignore the plug-in warning.') end
		end
	end

	if logic.shouldUseRedsHelper then
		Observe('modAutolootRedsHelper', 'LastPhoneMessagePopupGameController;PhoneMessagePopupGameController', function(this)
			if IsDefinedS(self) then lastPhoneMessagePopupGameController = Ref.Weak(this) end
		end)

		Observe('modAutolootRedsHelper', 'LastDialogWidgetGameController;dialogWidgetGameControllerInt32', function(this, hubsCount)
			lastDialogWidgetGameController = Ref.Weak(this)
			logic.isAnyDialogOnScreen = hubsCount > 0
			if hubsCount < 1 then
				logic.lastHubCountReset = os.clock()
			end
		end)

		Observe('modAutolootRedsHelper', 'LastInteractionUIBase;InteractionUIBase', function(this)
			lastInteractionUIBase = Ref.Weak(this)
		end)

		Observe('modAutolootRedsHelper', 'LastCursorDeviceGameController;cursorDeviceGameControllerVariant', function(this, value)
			lastCursorDeviceGameController = Ref.Weak(this)
			local v = FromVariant(value)
			if not v then lastTerminalInteractionActive = false return end
			lastTerminalInteractionActive = v.terminalInteractionActive
			logic.isNativeHubLeftoverActive = false
		end)

		Observe('modAutolootRedsHelper', 'LastLootingController;LootingControllerBool', function(this, isShow)
			lastLootingController = Ref.Weak(this)
			logic.isLootDialogOnScreen = isShow
			if isShow then logic.isNativeHubLeftoverActive = false end
		end)

		Observe('modAutolootRedsHelper', 'AddToObjectMappins;GameObjectIScriptableBool', function(owner, mappinObjectRef, forceNew)
			logic.addToObjectMappins(Ref.Weak(owner), Ref.Weak(mappinObjectRef), forceNew)
		end)
	else
		Observe('PhoneMessagePopupGameController', 'OnInitialize', function(self) if IsDefinedS(self) then lastPhoneMessagePopupGameController = Ref.Weak(self) end end)

		ObserveAfter("dialogWidgetGameController", "OnDialogsActivateHub", function(this);
			lastDialogWidgetGameController = Ref.Weak(this)
			logic.isAnyDialogOnScreen = this.hubAvailable
			if not this.hubAvailable then logic.lastHubCountReset = os.clock() end
		end);

		Observe('dialogWidgetGameController', 'AdjustHubsCount', function(this, evt)
			lastDialogWidgetGameController = Ref.Weak(this)
			logic.isAnyDialogOnScreen = evt > 0
			if evt < 1 then logic.lastHubCountReset = os.clock() end
		end)

		ObserveAfter('InteractionUIBase', 'OnInitialize', function(self);
			lastInteractionUIBase = Ref.Weak(self)
		end)

		ObserveAfter('InteractionUIBase', 'OnDialogsActivateHub', function(self);
			lastInteractionUIBase = Ref.Weak(self)
		end)

		Observe('cursorDeviceGameController', 'OnInteractionStateChange', function(this, value)
			lastCursorDeviceGameController = Ref.Weak(this)
			local v = FromVariant(value)
			if not v then lastTerminalInteractionActive = false return end
			lastTerminalInteractionActive = v.terminalInteractionActive
			logic.isNativeHubLeftoverActive = false
		end)

		Observe('LootingController', 'Show', function(self)
			lastLootingController = Ref.Weak(self)
			logic.isLootDialogOnScreen = true
			logic.isNativeHubLeftoverActive = false
		end)

		Observe('LootingController', 'Hide', function(self)
			logic.isLootDialogOnScreen = false
			lastLootingController = Ref.Weak(self)
		end)

		ObserveAfter('gameItemDropObject', 'OnItemEntitySpawned', function(self)
			logic.addToObjectMappins(Ref.Weak(self), nil)
		end)

		Observe('GameplayRoleComponent', 'CreateRoleMappinData', function(self)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self), true)
		end)

		ObserveAfter('GameplayRoleComponent', 'OnLogicReady', function(self)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self))
		end)

		Observe('GameplayRoleComponent', 'ShowRoleMappinsByTask', function(self)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self))
		end)

		ObserveAfter('GameplayRoleComponent', 'ShowRoleMappins', function(self)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self))
		end)

		Observe('GameplayRoleComponent', 'SetForceHidden', function(self, isHidden)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self), (self.isForceHidden and not isHidden))
		end)

		ObserveAfter('GameplayRoleComponent', 'OnGameAttach', function(self)
			local owner = Ref.Weak(self:GetOwner())
			logic.addToObjectMappins(owner, Ref.Weak(self), true)
		end)
	end

	Observe('gameInventoryScriptCallback', 'OnItemAdded', function()
		if not logic.isLootingTime() then return end
		logic.hideLootMarkers()
	end)

	local lookForLeftovers = true
	Observe('PlayerPuppet', 'OnGameAttached', function(self)
		if self:IsReplacer() then return end
		if logic.settings and type(logic.config) == 'table' and type(logic.config.loadConfig) == 'function' then
			local newSettings = logic.config.loadConfig("config/config.json", logic.settings)
			if type(newSettings) == 'table' then
				for k, v in pairs(newSettings) do logic.settings[k] = v end
			end
		end
		logic.isNativeHubLeftoverActive = false
		lookForLeftovers = true
		if logic.resetAutoLootStates then logic.resetAutoLootStates() end
		logic.resetVariables()
	end)

	Observe('PlayerPuppet', 'OnMakePlayerVisibleAfterSpawn', function (this)
		lookForLeftovers = false
	end)

	Observe('interactionWidgetGameController', 'OnUpdateInteraction', function(this, argValue);
		if not lookForLeftovers then return end
		if not this.root then return end;
		local data = FromVariant(argValue);
		if not data.active then return end;
		logic.isNativeHubLeftoverActive = true
		lookForLeftovers = false
	end)
	
	ObserveAfter('InteractionUIBase', 'OnInteractionData', function(this)
		lastInteractionUIBase = Ref.Weak(this)
		logic.isNativeHubLeftoverActive = false
	end)
end

function logic.addToObjectMappins(owner, mappinObjectRef, forceNew)
	if not owner then return end

	local mappinData = nil
	if IsDefinedS(mappinObjectRef) then
		mappinData = mappinObjectRef.mappins[#mappinObjectRef.mappins]
	end

	local ownerHash = nil
	pcall(function() ownerHash = owner:GetEntityID().hash end)
	if not ownerHash then return end
	local ownerHashStr = tostring(ownerHash)
	if ownerHashStr == '1ULL' then return end

	if not objectMappins[ownerHashStr] then
		objectMappinsCount = objectMappinsCount + 1
		objectMappins[ownerHashStr] = {isNew = true, mappinObjectRef = mappinObjectRef}
	else
		if forceNew then
			objectMappins[ownerHashStr] = {isNew = true, mappinObjectRef = mappinObjectRef}
		else
			objectMappins[ownerHashStr].mappinObjectRef = mappinObjectRef
		end
	end
end

function logic.hideLootMarkers()
	for ownerHashStr, mappinRec in pairs(customLootMappins) do
		if mappinRec.isLootOn then
			local mappin = mappinRec.mappin
			if mappin.mappinObjectRef then
				if IsDefinedS(mappin.mappinObjectRef) then
					if mappin.mappinObjectRef.mappins then
						local owner = logic.findEntityByIDHashStr(ownerHashStr)
						if owner then
							if owner:IsA('NPCPuppet') then
								local hideLootMappin = false
								local result, items = Game.GetTransactionSystem():GetItemList(owner)
								if result then if items then hideLootMappin = #items == 0 end end
								if hideLootMappin then
									for i = #mappin.mappinObjectRef.mappins, 1, -1 do
										if mappin.mappinObjectRef.mappins[i].mappinVariant == gamedataMappinVariant.LootVariant then
											mappin.mappinObjectRef:HideRoleMappins()
											mappinRec.isLootOn = false
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

function logic.lootInRange(range, lootInView, lootVisible, audioFeedback)
	if not logic.isLootingTime() then return end
	if not range then range = 1000 end
	if type(range) ~= 'number' then range = 1000 end
	local lootInRange = range > 0
	local forceShard = true
	if not lootInRange then range = 10000 end
	lootInView = true
	local objectsProcessed = {}

	local player = Game.GetPlayer()
	local gameObj = nil
	local isAnythingLooted = false
	local result, items = false, nil

	local rangeSquared = range * range
	local playerPos = player:GetWorldPosition()

	if objectMappinsCount > 0 then
		for ownerHashStr, mappin in pairs(objectMappins) do
			if mappin then
				if mappin.isNew then
					gameObj = logic.findEntityByIDHashStr(ownerHashStr)
					if logic.isObjectOfInterest(gameObj) then
						if logic.isNpcSafeToLoot(gameObj) then
							local hasItemsToLoot, objectHasLootItems, ownerHasLootItems = false, false, false
							result, items = Game.GetTransactionSystem():GetItemList(gameObj)
							if result then if items then if #items > 0 then hasItemsToLoot = true objectHasLootItems = true end end end
							local gameObjOwner = nil
							result = false
							pcall(function() gameObjOwner = gameObj:GetOwner() end)
							if gameObjOwner then result, items = Game.GetTransactionSystem():GetItemList(gameObjOwner) end
							if result then if items then if #items > 0 then hasItemsToLoot = true ownerHasLootItems = true end end end
							if hasItemsToLoot then
								local takeIt = true
								if lootInRange then
									local gameObjPos = gameObj:GetWorldPosition()
									takeIt = Vector4.DistanceSquared(playerPos, gameObjPos) <= rangeSquared
								end
								-- EVIL
								takeIt = true
								if takeIt then
									-- EVIL
									lootInView = true
									if lootInView then takeIt = Game.GetCameraSystem():IsInCameraFrustum(gameObj, 0.5, 0.2) end
									-- EVIL
									takeIt = true
									if takeIt then
										takeIt = true -- ??
										-- EVIL
										lootVisible = true
										if lootVisible then takeIt = logic.isObjectVisibleToPlayer(gameObj) end
										-- EVIL
										takeIt = true
										if takeIt then
											local lootStep1Result, lootStep2Result = lootResult.nothingToLoot, lootResult.nothingToLoot
											if objectHasLootItems then
												result = logic.lootObjectItems(gameObj, forceShard, true)
												objectsProcessed[tostring(gameObj:GetEntityID().hash)] = true
												lootStep1Result = result
												if result > lootResult.nothingToLoot then
													isAnythingLooted = true
												end
											end

											if ownerHasLootItems then
												if gameObjOwner then
													gameObj = gameObjOwner
													result = logic.lootObjectItems(gameObj, forceShard, false)
													objectsProcessed[tostring(gameObj:GetEntityID().hash)] = true
													lootStep2Result = result
													if result > lootResult.nothingToLoot then
														isAnythingLooted = true
													end
												end
											end

											local shouldSetMarker = false
											if lootStep1Result == lootResult.allItemsFailed or lootStep1Result == lootResult.protectedObject or lootStep1Result == lootResult.partialLoot then shouldSetMarker = true end
											if not shouldSetMarker then
												if lootStep2Result == lootResult.allItemsFailed or lootStep2Result == lootResult.protectedObject or lootStep2Result == lootResult.partialLoot then shouldSetMarker = true end
											end
											if shouldSetMarker then
												if gameObj:IsA('NPCPuppet') then
													mappin.mappinObjectRef:ShowRoleMappins()
													customLootMappins[ownerHashStr] = {mappin = mappin, isLootOn = true}
												end
											end
										end
									end
								end
							end
						end
					else
						mappin.isNew = false
					end
				end
			end
		end
	end

	local gameObjEntityIdHashStr = ''
	local targetingSystem = Game.GetTargetingSystem()
	local objects = {}
	local searchQuery = TSQ_ALL()
	searchQuery.testedSet = gameTargetingSet.Visible
	searchQuery.maxDistance = range
	searchQuery.includeSecondaryTargets = false
	searchQuery.ignoreInstigator = true

	gameObj = Game.GetTargetingSystem():GetLookAtObject(player, false, false)
	if gameObj ~= nil then
		gameObjEntityIdHashStr = tostring(gameObj:GetEntityID().hash)

		if objectsProcessed[gameObjEntityIdHashStr] then
			result = 0
		else
			local takeIt = true
			if lootInRange then
				local gameObjPos = gameObj:GetWorldPosition()
				takeIt = Vector4.DistanceSquared(playerPos, gameObjPos) <= rangeSquared
			end
			if takeIt then
				if logic.isObjectLootable(gameObj, gameObjEntityIdHashStr, true) then
					result = logic.lootObjectItems(gameObj, forceShard, false)
					objectsProcessed[gameObjEntityIdHashStr] = true
					if result > lootResult.nothingToLoot then
						isAnythingLooted = true
					else
						local owner = nil
						pcall(function() owner = gameObj:GetOwner() end)
						if owner then
							gameObjEntityIdHashStr = tostring(owner:GetEntityID().hash)
							if objectsProcessed[gameObjEntityIdHashStr] then
							else
								if not string.find(owner:ToString(), 'gameLootSlot') then
									if gameObj:GetEntityID().hash ~= owner:GetEntityID().hash then
										result = logic.lootObjectItems(owner, forceShard, false)
										objectsProcessed[gameObjEntityIdHashStr] = true
										if result > lootResult.nothingToLoot then
											isAnythingLooted = true
										end
									end
								end
							end
						end
					end
				else
					objectsProcessed[gameObjEntityIdHashStr] = true
				end
			end
		end
	end

	_, objects = targetingSystem:GetTargetParts(player, searchQuery)
	for _, v in ipairs(objects) do
		gameObj = v:GetComponent(v):GetEntity()
		gameObjEntityIdHashStr = tostring(gameObj:GetEntityID().hash)
		if objectsProcessed[gameObjEntityIdHashStr] then
			result = 0
		else
			local takeIt = true
			if lootInRange then
				local gameObjPos = gameObj:GetWorldPosition()
				takeIt = Vector4.DistanceSquared(playerPos, gameObjPos) <= rangeSquared
			end
			if takeIt then
				if logic.isObjectLootable(gameObj, gameObjEntityIdHashStr, true) then
					result = logic.lootObjectItems(gameObj, forceShard, false)
					if result > lootResult.nothingToLoot then
						isAnythingLooted = true
					else
						local owner = nil
						pcall(function() owner = gameObj:GetOwner() end)
						if owner then
							gameObjEntityIdHashStr = tostring(owner:GetEntityID().hash)
							if objectsProcessed[gameObjEntityIdHashStr] then
							else
								if not string.find(owner:ToString(), 'gameLootSlot') then
									if gameObj:GetEntityID().hash ~= owner:GetEntityID().hash then
										result = logic.lootObjectItems(owner, forceShard, false)
										if result > lootResult.nothingToLoot then
											isAnythingLooted = true
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	logic.lastLootCompletedTime = os.clock()
	if audioFeedback then if isAnythingLooted then Game.GetAudioSystem():PlayLootAllSound() end end
end

local angleIncrements = {0, 5, -5, 10, -10, 15, -15}
local elevationIncrements = {0, 0.33, 0.45, 0.5}

function logic.isObjectVisibleToPlayer(gameObj)
	if not gameObj then return false end
	if not IsDefinedS(gameObj) then return false end
	if not gameObj:IsA('gameObject') then return false end

	local player = Game.GetPlayer()
	local playerPos = player:GetWorldPosition()
	local objectPos = gameObj:GetWorldPosition()
	local isVisble = false

	isVisble = Game.GetSenseManager():IsObjectVisible(player:GetEntity(), gameObj:GetEntity())
	if isVisble then return true end

	local playerEyesPos, forward = Game.GetTargetingSystem():GetCrosshairData(player)
	local playerToEyesDist2D = Vector4.Distance2D(playerPos, playerEyesPos) + 0.02
	playerEyesPos.z = playerEyesPos.z + 0.02
	local playerToObjectAngle = Vector4.new(objectPos.x - playerEyesPos.x, objectPos.y - playerEyesPos.y, 0, 0):ToRotation().yaw + 90
	playerEyesPos = Vector4.new(playerPos.x + playerToEyesDist2D * math.cos(math.rad(playerToObjectAngle)), playerPos.y + playerToEyesDist2D * math.sin(math.rad(playerToObjectAngle)), playerEyesPos.z, 1)

	isVisble = Game.GetSenseManager():IsPositionVisible(playerEyesPos, objectPos)
	if isVisble then return true end

	isVisble = Game.GetSenseManager():IsPositionVisible(objectPos, playerEyesPos)
	if isVisble then return true end

	local eyesToObjectDist2D = Vector4.Distance2D(playerEyesPos, objectPos)
	if eyesToObjectDist2D ~= 0 then
		local objectToPlayerEyesAngle = Vector4.new(playerEyesPos.x - objectPos.x, playerEyesPos.y - objectPos.y, 0, 0):ToRotation().yaw + 90
		local angleShiftFactor = 0.003 * 360 / eyesToObjectDist2D

		if elevationIncrements then
			local newPlayerEyesPos = Vector4.new(playerEyesPos)

			if not angleIncrements then angleIncrements = {0} elseif #angleIncrements == 0 then angleIncrements = {0} end
			for _, angleShift in ipairs(angleIncrements) do

				if angleShift ~= 0 then
					angleShift = angleShift * angleShiftFactor
					local newAngleRad = math.rad(objectToPlayerEyesAngle+angleShift)
					newPlayerEyesPos = Vector4.new(objectPos.x + eyesToObjectDist2D * math.cos(newAngleRad), objectPos.y + eyesToObjectDist2D * math.sin(newAngleRad), playerEyesPos.z, 1)
				end

				local elevatedObjectPos = Vector4.new(objectPos)
				for _, elevationIncrement in ipairs(elevationIncrements) do
					elevatedObjectPos.z = elevatedObjectPos.z + elevationIncrement

					isVisble = Game.GetSenseManager():IsPositionVisible(newPlayerEyesPos, elevatedObjectPos)
					if isVisble then return true end

					isVisble = Game.GetSenseManager():IsPositionVisible(elevatedObjectPos, newPlayerEyesPos)
					if isVisble then return true end
				end
			end
		end
	end

	local hitPoint, hitPoints = logic.getHitPointFromTo(playerEyesPos, objectPos)
	if hitPoint then
		if not hitPoints then hitPoints = {} end
		local objectDist = Vector4.Distance(playerPos, objectPos)
		local hitPointDist = Vector4.Distance(playerPos, hitPoint)
		local dif = objectDist - hitPointDist

		if hitPointDist > objectDist then
			isVisble = false
		elseif (#hitPoints > 0 and (string.find(hitPoints[#hitPoints].materials, 'concrete') or string.find(hitPoints[#hitPoints].materials, 'asphalt'))) then
			isVisble = false
		elseif dif < 0.33 then
			isVisble = true
		elseif (dif < 1 and Game.GetAINavigationSystem():IsPointOnNavmesh(gameObj, hitPoint, Vector4.new(0.3, 0.3, 0.3, 1))) then
			isVisble = true
		else
			isVisble = false
		end
	else
		isVisble = true
	end

	return isVisble
end

local excludedClasses = {
	['AccessPoint'] = true,
	['ActivatedDeviceTransfromAnim'] = true,
	['ActivatedDeviceTrapDestruction'] = true,
	['AOEArea'] = true,
	['AOEEffector'] = true,
	['ApartmentScreen'] = true,
	['ArcadeMachine'] = true,
	['BasicDistractionDevice'] = true,
	['BillboardDevice'] = true,
	['BlindingLight'] = true,
	['CleaningMachine'] = true,
	['Computer'] = true,
	['ConfessionBooth'] = true,
	['CrossingLight'] = true,
	['DataTerm'] = true,
	['DisplayGlass'] = true,
	['DisposalDevice'] = true,
	['Door'] = true,
	['DropPoint'] = true,
	['ElectricBox'] = true,
	['ElectricLight'] = true,
	['ElevatorFloorTerminal'] = true,
	['ExplosiveDevice'] = true,
	['ExplosiveTriggerDevice'] = true,
	['FakeDoor'] = true,
	['Fan'] = true,
	['forklift'] = true,
	['FuseBox'] = true,
	['GenericDevice'] = true,
	['GlitchedTurret'] = true,
	['HoloFeeder'] = true,
	['IceMachine'] = true,
	['Intercom'] = true,
	['InvisibleSceneStash'] = true,
	['Jukebox'] = true,
	['Ladder'] = true,
	['LcdScreen'] = true,
	['LiftDevice'] = true,
	['NcartTimetable'] = true,
	['NetrunnerChair'] = true,
	['PachinkoMachine'] = true,
	['Radio'] = true,
	['Reflector'] = true,
	['RoadBlock'] = true,
	['SecurityAlarm'] = true,
	['SecurityTurret'] = true,
	['SmartWindow'] = true,
	['SmokeMachine'] = true,
	['Speaker'] = true,
	['Stash'] = true,
	['SurveillanceCamera'] = true,
	['Terminal'] = true,
	['Toilet'] = true,
	['TrafficLight'] = true,
	['TrafficZebra'] = true,
	['TV'] = true,
	['VendingMachine'] = true,
	['Wardrobe'] = true,
	['WeakFence'] = true,
	['WeaponVendingMachine'] = true,
	['Window'] = true,
	['WindowBlinders'] = true,
}

function logic.isObjectOfInterest(gameObj)
	if not gameObj then return false end
	if not IsDefinedS(gameObj) then return false end
	local classNameStr = ' '
	local classNameStr = gameObj:ToString()
	if excludedClasses[classNameStr] then return false end

	local result, data = pcall(function() return gameObj:IsA('gameObject') end)
	if not result then return false end
	if not data then return false end
	if gameObj:IsVehicle() then return false end
	if gameObj:IsPlayer() then return false end
	if gameObj:IsNPC() then if gameObj.isCrowd then return false end end

	if string.find(classNameStr, 'Turret') then return false end
	if gameObj:IsA('gameItemDropObject') then
		local itemObject = gameObj:GetItemObject()
		if itemObject then
			if itemObject:IsA('gameweaponObject') then
				if itemObject.isHeavyWeapon then return false end
			end
		end
	end

	return true
end

function logic.isNpcSafeToLoot(gameObj)
	if gameObj:IsNPC() then
		if gameObj:IsDead() then return true end
		if not (gameObj:GetKiller() == nil) then return true end
		if gameObj:IsDefeated() then return true end
		return false
	end
	return true
end

function logic.isObjectLootable(gameObj, gameObjEntityIdHashStr, isClassicScan)
	if excludedClasses[gameObj:ToString()] then return false end
	if gameObj:IsA('ScriptedPuppet') then if gameObj:IsHuman() then return true end end
	if isClassicScan then return true end
	if objectMappinsCount == 0 then return false end
	if not gameObjEntityIdHashStr then gameObjEntityIdHashStr = tostring(gameObj:GetEntityID().hash) end
	if not objectMappins[gameObjEntityIdHashStr] then return false end
	if not objectMappins[gameObjEntityIdHashStr].mappinObjectRef then return false end
	if not IsDefinedS(objectMappins[gameObjEntityIdHashStr].mappinObjectRef) then return false end
	if not objectMappins[gameObjEntityIdHashStr].mappinObjectRef.mappins then return false end
	if #objectMappins[gameObjEntityIdHashStr].mappinObjectRef.mappins == 0 then return false end
	return true
end

function logic.lootObjectItems(gameObj, forceShard, skipPreCheck)
	if not skipPreCheck then
		if not logic.isObjectOfInterest(gameObj) then return lootResult.notLootObject end
		if not logic.isNpcSafeToLoot(gameObj) then return lootResult.notLootObject end
	end
	local protectQuestObject = true

	local isObjectLockProtected = false
	local isObjectQuestProtected = false
	local isObjectQuestSiteProtected = false

	if forceShard then
		if string.find(gameObj:ToString(), 'Shard') then
			protectQuestObject = false
		end
	end

	if gameObj:IsA('gameContainerObjectBase') then
		if gameObj:IsA('ShardCaseContainer') then
			if protectKeyCards and gameObj.itemTDBID and RPGManager.GetItemType(ItemID.FromTDBID(gameObj.itemTDBID)) == gamedataItemType.Gen_Keycard then return lootResult.protectedObject end
		else
			if gameObj:IsLocked(Game.GetPlayer()) then return lootResult.protectedObject end
		end
	end

	if protectQuestObject then if gameObj:IsQuest() then return lootResult.protectedObject end end
	if logic.isObjectAtQuestSite(gameObj) then return lootResult.protectedObject end

	local isObjectWeaponGradeProtected = false
	if gameObj:IsA('gameItemDropObject') then
		local itemObject = gameObj:GetItemObject()
		if itemObject then
			if itemObject:IsA('gameweaponObject') then
				itemObject = gameObj:GetItemObject()
				if itemObject then
					if isGameV2 then
						if gameObj.isIconic and itemObject.isIconic then
							isObjectWeaponGradeProtected = true
						end
					else
						if itemObject.isIconic then
							isObjectWeaponGradeProtected = true
						end
					end
				end
			end
		end
	end

	local objectPosition = gameObj:GetWorldPosition()
	if isValidVector4(objectPosition) then
		if type(protectedSpecialItems) == 'table' then
			if not IsDefinedS(questsSystem) then questsSystem = Ref.Weak(Game.GetQuestsSystem()) end
			for _, protectedItem in ipairs(protectedSpecialItems) do
				if protectedItem.position then
					if Vector4.DistanceSquared(objectPosition, protectedItem.position) < 0.36 then
						if type(protectedItem.factName) == 'string' then
							if questsSystem:GetFactStr(protectedItem.factName) < 1 then
								return lootResult.protectedObject
							end
						else
							return lootResult.protectedObject
						end
					end
				end
			end
		end

		if type(collectedPoiMappins) == 'table' then
			for _, mappinData in pairs(collectedPoiMappins) do
				if not IsDefinedS(mappinData.mappin) then mappinData = nil
				elseif mappinData.position then
					if Vector4.DistanceSquared(objectPosition, mappinData.position) < 0.1225 then
						return lootResult.protectedObject
					end
				end
			end
		end
	end

	local result, items = Game.GetTransactionSystem():GetItemList(gameObj)
	if result then
		if #items > 0 then
			local lootedItems, totalItems = 0, #items
			for i, item in ipairs(items) do
				if IsDefinedS(item) then
					local isItemQuestProtected = false
					local isHeavyWeaponItem = false
					local isItemWeaponGradeProtected = false

					local questFound = false
					local itemId = item:GetID():GetTDBID()
					local itemRecord = TweakDBInterface.GetItemRecord(itemId)
					if itemRecord then
						local itemSecondaryAction = itemRecord:ItemSecondaryAction()
						if itemSecondaryAction then
							local appendedTweakDBID = TweakDBID.new(itemSecondaryAction:GetID(), ".journalEntry")
							local journalPath = TweakDBInterface.GetString(appendedTweakDBID, "")
							local journalEntry = Game.GetJournalManager():GetEntryByString(journalPath, "gameJournalOnscreen")

							if journalEntry then
								local level = 0
								while (journalEntry and not journalEntry:IsA('gameJournalFolderEntry') and level < 10) do
									journalEntry = Game.GetJournalManager():GetParentEntry(journalEntry)
									level = level + 1

								end
								if journalEntry then
									if #allJournalQuestEntries == 0 then
										allJournalQuestEntries = journalMappinExtractor.getAllJournalQuestEntries()
										if not allJournalQuestEntries then allJournalQuestEntries = {} end
									end

									for i, qe in ipairs(allJournalQuestEntries) do
										if not questFound then if journalEntry.id == qe.id then questFound = true end end
									end
								end
							end
						end
					end

					isItemQuestProtected = questFound

					if not isItemQuestProtected then
						if type(protectedSpecialItems) == 'table' then
							for _, protectedItem in ipairs(protectedSpecialItems) do
								if protectedItem.id then
									if itemId.hash == protectedItem.id.hash and itemId.length == protectedItem.id.length then
										isItemQuestProtected = true
									end
								end
							end
						end
					end
					
					local itemType = item:GetItemType()
					if itemType then
						isHeavyWeaponItem = itemType == gamedataItemType.Wea_HeavyMachineGun
						if string.find(itemType.value, 'Wea_') then
							isItemWeaponGradeProtected = item:GetStatValueByType(gamedataStatType.IsItemIconic) > 0
						end
					end

					if not isHeavyWeaponItem and not isObjectWeaponGradeProtected and not isItemWeaponGradeProtected and not isObjectLockProtected and not isItemQuestProtected and not isObjectQuestProtected and not isObjectQuestSiteProtected then
						if Game.GetTransactionSystem():TransferItem(gameObj, Game.GetPlayer(), item:GetID(), item:GetQuantity()) then
							lootedItems = lootedItems + 1
						end
					end
				end
			end

			if lootedItems > 0 then
				if gameObj:IsA('gameContainerObjectBase') or gameObj:IsA('ShardCaseContainer') then
					if not gameObj.wasOpened then
						pcall(function() gameObj:OpenContainerWithTransformAnimation() end)
						gameObj.wasOpened = true
					end
				end
			end

			if lootedItems > 0 then
				if logic.isLootDialogOnScreen then
					if lastLootingController then
						if IsDefinedS(lastLootingController) then
							lastLootingController:Hide()
						end
					end
				end
				if lootedItems == totalItems then
					return lootResult.allLooted
				else
					return lootResult.partialLoot
				end
			else
				return lootResult.allItemsFailed
			end
		else
			return lootResult.nothingToLoot
		end
	else
		return lootResult.nothingToLoot
	end

	return lootResult.generalFailure
end

function logic.isObjectAtQuestSite(gameObj)
	if isQuestMappWithinRangeByJournal(gameObj, 0.5) then return true end
	if isWorldMappinOfTypeWithinRange(gameObj, 0.5, 'Quest') then return true end
	return false
end

function isQuestMappWithinRangeByJournal(gameObj, range)
	if not gameObj then return false end
	if not IsDefinedS(gameObj) then return false end
	if not gameObj:IsA('gameObject') then return false end
	if not range then range = 0.5 end
	if type(range) ~= 'number' then range = 0.5 end

	local capturedQuestMappins = journalMappinExtractor.getCurrentQuestsMappins()
	if not capturedQuestMappins then return false end
	if not #capturedQuestMappins == 0 then return false end

	local objectPos = gameObj:GetWorldPosition()

	closeMappins = {}
	for _, mappin in ipairs(capturedQuestMappins) do

		if math.abs(mappin.pos.x - objectPos.x) <= range then
			if math.abs(mappin.pos.y - objectPos.y) <= range then
				if math.abs(mappin.pos.z - objectPos.z) <= range then
					local takeIt = true
					if takeIt then table.insert(closeMappins, mappin) end
				end
			end
		end
	end

	if #closeMappins == 0 then return false end
	if #closeMappins == 1 then return closeMappins[1] end

	lowestDistanceIndex = 0
	lowestDistanceSquared = 1000000000

	for i = 1, #closeMappins do
		local distSquared = Vector4.DistanceSquared(objectPos, closeMappins[i].pos)
		if distSquared < lowestDistanceSquared then
			lowestDistanceSquared = distSquared
			lowestDistanceIndex = i
		end
	end

	if lowestDistanceIndex > 0 then
		if lowestDistanceSquared <= range * range then
			return closeMappins[lowestDistanceIndex]
		end
	end

	return false
end

function isWorldMappinOfTypeWithinRange(gameObj, range, typeFilterStr1, typeFilterStr2)
	if not gameObj then return false end
	if not IsDefinedS(gameObj) then return false end
	if not gameObj:IsA('gameObject') then return false end
	if not range then range = 0.5 end
	if type(range) ~= 'number' then range = 0.5 end
	if type(typeFilterStr1) ~= 'string' then typeFilterStr1 = false end
	if type(typeFilterStr2) ~= 'string' then typeFilterStr2 = false end
	local noTypeFilters = not typeFilterStr1 and not typeFilterStr2

	if not worldMappins then worldMappins = {} end
	worldMappins = Game.GetMappinSystem():GetMappins(gamemappinsMappinTargetType.World)
	if not worldMappins then return false end
	if #worldMappins == 0 then return false end

	local objectPos = gameObj:GetWorldPosition()

	closeMappins = {}
	for _, mappin in ipairs(worldMappins) do
		if math.abs(mappin.worldPosition.x - objectPos.x) <= range then
			if math.abs(mappin.worldPosition.y - objectPos.y) <= range then
				if math.abs(mappin.worldPosition.z - objectPos.z) <= range then
					local takeIt = false
					if noTypeFilters then
						takeIt = true
					else
						if typeFilterStr1 then if string.find(mappin.type.value, typeFilterStr1) then takeIt = true end end
						if takeIt ~= true then if typeFilterStr2 then if string.find(mappin.type.value, typeFilterStr2) then takeIt = true end end end
					end
					if takeIt then table.insert(closeMappins, mappin) end
				end
			end
		end
	end

	if #closeMappins == 0 then return false end
	if #closeMappins == 1 then return closeMappins[1] end

	lowestDistanceIndex = 0
	lowestDistanceSquared = 1000000000

	for i = 1, #closeMappins do
		local distSquared = Vector4.DistanceSquared(objectPos, closeMappins[i].worldPosition)
		if distSquared < lowestDistanceSquared then
			lowestDistanceSquared = distSquared
			lowestDistanceIndex = i
		end
	end

	if lowestDistanceIndex > 0 then
		if lowestDistanceSquared <= range * range then
			return closeMappins[lowestDistanceIndex]
		end
	end

	return false
end

function logic.couldStartNewLootingCycle()
	logic.isPlayerInWorkspot = Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer())
	if logic.isPlayerInWorkspot then return false end
	if isAnyGamePausingScreen() then return false end
	if isPlayerSpecialMode() then return false end
	if isMessagePopupOnScreen() then return false end
	if isPlayerInVehicle() then return false end
	if isPlayerInComputerControl() then return end
	if isPlayerInFastTravel() then return false end
	if isPlayerInBraindance() then return false end
	if isExcludedSpecialQuestCase() then return false end
	return true
end

function logic.isLootingTime()
	logic.isPlayerInWorkspot = Game.GetWorkspotSystem():IsActorInWorkspot(Game.GetPlayer())

	if type(logic.cooldown) == 'number' then if os.clock() > logic.cooldown then logic.cooldown = 0 end else logic.cooldown = 0 end
	if logic.cooldown > 0 then return end

	logic.isAnyDialogOnScreen = isDialogOpen()
	logic.isAnyOtherInteractonOnScreen = isInteractionsOpen()
	
	if lastTerminalInteractionActive then
		if lastCursorDeviceGameController then
			if IsDefinedS(lastCursorDeviceGameController) then
				if not lastCursorDeviceGameController.cursorDevice:IsVisible() then
					lastTerminalInteractionActive = false
				end
			else
				lastTerminalInteractionActive = false
			end
		else
			lastTerminalInteractionActive = false
		end
	end
	if not logic.isAnyOtherInteractonOnScreen then logic.isAnyOtherInteractonOnScreen = lastTerminalInteractionActive end
	if not logic.isLootDialogOnScreen then
		if logic.isAnyDialogOnScreen then
			logic.cooldown = os.clock() + 0.75
			return false
		end
		if logic.isAnyOtherInteractonOnScreen then
			logic.cooldown = os.clock() + 0.25
			return false
		end
	end

	if logic.isPlayerInWorkspot then return false end
	if isAnyGamePausingScreen() then return false end
	if isPlayerSpecialMode() then return false end
	if isMessagePopupOnScreen() then return false end
	-- EVIL
	-- if isPlayerInVehicle() then return false end
	if isPlayerScanning() then return false end
	if isPlayerInComputerControl() then return end
	if isPlayerInFastTravel() then return false end
	if isPlayerInBraindance() then return false end
	if isExcludedSpecialQuestCase() then return false end

	logic.cooldown = 0
	return true
end


local excludedSpecialQuestCases = {
	{questID = 'q115_afterlife', questPhase = '02_afterlife', questObjective = '02e_talk_nix'},
	{questID = 'q115_afterlife', questPhase = '02_afterlife', questObjective = '02b_put_on_suit'},
	{questID = 'q114_03_attack_on_arasaka_tower', questPhase = '09_mikoshi', questObjective = '01_defeat_adam'},
	{questID = 'q114_03_attack_on_arasaka_tower', questPhase = '09_mikoshi', questObjective = '03_go_to_access'},
	{questID = 'q203_legend', questPhase = 'penthouse', questObjective = 'get_shower'},
	{questID = 'q203_legend', questPhase = 'penthouse', questObjective = 'put_on_clothes'},
	{questID = 'q203_legend', questPhase = 'cosmos', questObjective = 'get_guns'},
	{questID = 'mq011_wilson', questPhase = '00_wilson', questObjective = '02_talk_to_wilson'},
	{questID = 'mq011_wilson', questPhase = '00_wilson', questObjective = '03_enter_range'},
	{questID = 'mq011_wilson', questPhase = '00_wilson', questObjective = '04_listen_instructions'},
	{questID = 'mq011_wilson', questPhase = '01_competition', questObjective = '00b_ready'},
}

function isExcludedSpecialQuestCase()
	if not excludedSpecialQuestCases then return false end

	local objective = Game.GetJournalManager():GetTrackedEntry()
	if not objective then return false end

	local phase = Game.GetJournalManager():GetParentEntry(objective)
	if not phase then return false end

	local questID = Game.GetJournalManager():GetParentEntry(phase)
	if not questID then return false end

	local objectiveStr = tostring(objective.id)
	local phaseStr = tostring(phase.id)
	local questIDStr = tostring(questID.id)
	
	if objective then
		for i, quest in ipairs(excludedSpecialQuestCases) do
			if quest.questObjective == objectiveStr then
				if phaseStr == quest.questPhase then
					if questIDStr == quest.questID then return true end
				end
			end
		end
	end
	return false
end

function isMessagePopupOnScreen()
	if not lastPhoneMessagePopupGameController then return false end
	return IsDefinedS(lastPhoneMessagePopupGameController)
end

function isDialogOnScreen()
	local dialogChoiceHubs = FromVariant(Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UIInteractions):GetVariant(Game.GetAllBlackboardDefs().UIInteractions.DialogChoiceHubs))
	if dialogChoiceHubs then return #dialogChoiceHubs.choiceHubs > 0 end
	return false
end

function isDialogOpen()
	if isDialogOnScreen() then return true end
	if lastDialogWidgetGameController and IsDefined(lastDialogWidgetGameController) and lastDialogWidgetGameController.hubAvailable then return true end
	if lastInteractionUIBase and IsDefined(lastInteractionUIBase) then
		local rootWidget = lastInteractionUIBase:GetRootWidget()
		if rootWidget then
			local numChildren = rootWidget:GetNumChildren()
			if numChildren > 1 then
				local hubWidget = rootWidget:GetWidgetByPathName(CName.new('hub'))
				if hubWidget and hubWidget:GetNumChildren() > 1 then return true end
			end
		end
	end
	if type(logic.lastHubCountReset) == 'number' and os.clock() - logic.lastHubCountReset < 0.5 then return true end
	return false
end

function isLootingOpen()
	if not lastLootingController then return false end
	if not IsDefinedS(lastLootingController) then return false end
	return lastLootingController:IsShown()
end

function isInteractionsOpen()
	if logic.isNativeHubLeftoverActive then return true end
	if not lastInteractionUIBase then return false end
	if not IsDefinedS(lastInteractionUIBase) then return false end
	if not lastInteractionUIBase.AreInteractionsOpen then return false end
	return true
end

function isPlayerInVehicle()
	return GetMountedVehicle(Game.GetPlayer())
end

function isPlayerScanning()
	local scannerMode = false
	pcall(function() scannerMode = FromVariant(Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UI_Scanner):GetVariant(Game.GetAllBlackboardDefs().UI_Scanner.ScannerMode)) end)
	if scannerMode then if scannerMode.mode then if scannerMode.mode ~= gameScanningMode.Inactive then return true end end end
	return false
end

function isPlayerInBraindance()
	return Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().Braindance):GetBool(Game.GetAllBlackboardDefs().Braindance.IsActive)
end

function isPlayerInFastTravel()
	if Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().FastTRavelSystem):GetBool(Game.GetAllBlackboardDefs().FastTRavelSystem.FastTravelLoadingScreenFinished) then return false end	
	if not FromVariant(Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().FastTRavelSystem):GetVariant(Game.GetAllBlackboardDefs().FastTRavelSystem.DestinationPoint)) then return false end
	return true
end

function isPlayerInComputerControl()
	local isUIZoomDevice = false
	pcall(function() isUIZoomDevice = Game.GetBlackboardSystem():GetLocalInstanced(Game.GetPlayer():GetEntityID(), Game.GetAllBlackboardDefs().PlayerStateMachine):GetBool(Game.GetAllBlackboardDefs().PlayerStateMachine.IsUIZoomDevice) end)
	if isUIZoomDevice then return true end
	return false
end

function isAnyGamePausingScreen()
	result, blackboardSystem = pcall(function() return Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().UI_System) end)
	if not result then return true end
	if not IsDefinedS(blackboardSystem) then return true end
	if blackboardSystem:GetBool(Game.GetAllBlackboardDefs().UI_System.IsInMenu) then return true end
	if isPreGame() then return true end
	if isGamePaused() then return true end
	if isPlayerDetached() then return true end
	if isLoadingBar() then return true end
	if isRadialWheel() then return true end
	if isPhotoMode() then return true end
	if isTutorial() then return true end
	
	return false
end

function isPlayerSpecialMode()
	local player = Game.GetPlayer()
	if not player then return true end
	if not IsDefinedS(player) then return true end
	local sceneTier = player:GetSceneTier()
	if sceneTier >= 3 then
		local swimmingInt = tonumber(EnumInt(gamePSMHighLevel.Swimming))
		if swimmingInt > 0 then
			if sceneTier ~= swimmingInt then return end
		else
			return true
		end
	end
	if player:IsReplacer() then return true end
	if player:IsJohnnyReplacer() then return true end

	local appliedEffects = nil
	local gameObjectID = player:GetEntityID()
	pcall(function() appliedEffects = Game.GetStatusEffectSystem():GetAppliedEffects(gameObjectID) end)
	if appliedEffects then
		local currentTag = nil
		local isNormalStatus = true
		for i, statusEffect in ipairs(appliedEffects) do
			local record = statusEffect:GetRecord()
			local tags = record:GameplayTags()
			if tags then
				for ii = 1, #tags do
					currentTag = tags[ii].value
					if currentTag == 'Unconscious' then isNormalStatus = false
					elseif currentTag == 'Defeated' then isNormalStatus = false
					elseif currentTag == 'Cyberspace' then isNormalStatus = false
					elseif currentTag == 'CyberspacePresence' then isNormalStatus = false
					end
					if not isNormalStatus then return true end
				end
			end
		end
	else
		return true
	end

	return false
end

function isPreGame()
	return GetSingleton('inkMenuScenario'):GetSystemRequestsHandler():IsPreGame()
end

function isGamePaused()
	return GetSingleton('inkMenuScenario'):GetSystemRequestsHandler():IsGamePaused()
end

function isPlayerDetached()
	local streetCred = false
	pcall(function() streetCred = Game.GetStatsSystem():GetStatValue(Game.GetPlayer():GetEntityID(), 'StreetCred') end) --(c)psiberx)
	if not streetCred then return true end
	if streetCred < 1 then return true end
	return false
end

function isLoadingBar()
	if not lastLoadingScreenProgressBarController then return false end
	if not IsDefinedS(lastLoadingScreenProgressBarController) then return false end	
	local rootWidget = lastLoadingScreenProgressBarController.progressBarRoot
	if rootWidget then return rootWidget:IsVisible() end
	return false
end

function isRadialWheel()
	if Game.GetTimeSystem():IsTimeDilationActive('radial') then return true end -- (c)psiberx hint
	return false
end

function isPhotoMode()
	local isActive = false
	pcall(function() isActive = Game.GetBlackboardSystem():Get(Game.GetAllBlackboardDefs().PhotoMode):GetBool(Game.GetAllBlackboardDefs().PhotoMode.IsActive) end)
	if isActive then return true end
	return false
end

function isTutorial()
	if not lastTutorialMainController then return false end
	if not IsDefinedS(lastTutorialMainController) then return false end
	if lastTutorialMainController.tutorialActive then return true end
	return false
end


-- raycast helper:

-- this part is a modified extract from TargetingHelper.lua example by (c)psiberx
--https://github.com/WolvenKit/cet-examples
local obstacles = {
	'Static',
	'Terrain',
	'PlayerBlocker'
}

function logic.getHitPointFromTo(from, to, staticOnly)
	if not staticOnly then staticOnly = false end
	local filters = obstacles
	local results = {}
	for i, filter in ipairs(filters) do
		local success, result = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(from, to, filter, staticOnly, false)
		if success then
			table.insert(results, {
				distance = Vector4.DistanceSquared(from, Vector4.Vector3To4(result.position)),
				position = Vector4.Vector3To4(result.position),
				material = result.material
			})
		end
	end

	if #results == 0 then return nil, nil end

	local hitPoints = {}
	table.insert(hitPoints, {position = results[1].position, materials = results[1].material.value})
	local nearest = results[1]
	for i = 2, #results do
		if results[i].distance < nearest.distance then nearest = results[i] table.insert(hitPoints, {position = results[i].position, materials = results[i].material.value})
		elseif results[i].distance == nearest.distance then
			for ii = 2, #hitPoints do
				if hitPoints[ii].position.x == results[i].position.x then
					if hitPoints[ii].position.y == results[i].position.y then
						if hitPoints[ii].position.z == results[i].position.z then
							if hitPoints[ii].materials then
								hitPoints[ii].materials = hitPoints[ii].materials..','..results[i].material.value
							else
								hitPoints[ii].materials = results[i].material.value
							end
						end
					end
				end
			end
		end
	end

	return nearest.position, hitPoints
end

function logic.findEntityByIDHashStr(hashStr)
	if not hashStr then return nil end
	if type(hashStr) ~= 'string' then return nil end
	local result, data = pcall(function() return Game.FindEntityByID(entEntityID.new({ hash = loadstring('return ' .. hashStr, '')() })) end)
	if not result then return nil end
	return data
end

function isValidVector4(input)
	if type(input) ~= 'userdata' then return false end
	if not string.find(tostring(input), 'Vector4') then return false end
	if input:IsZero() then return false end
	return true
end

function IsDefinedS(gameObj)
	local result, val
	result, val = pcall(function() return IsDefined(gameObj) end)
	if result then return val else return false end
end

return logic