-------------------------------------------------------------------------------------------------------------------------------
-- Mod expansion and additional coding by anygoodname by keanuWheeze consent.
-- This mod shall not be redistributed or modified/renamed/rebranded and published as a separate mod without keanuWheeze and anygoodname permission.
-- To use code snippets from this mod in other mods requires a consent and a proper credit note.

-- v1.4.0 Sep 30, 2023
-- Based on (c)psiberx JournalScan script.
-- adapted to extract quest markers and mappins only for the Autoloot mod by anygoodname

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

----------------------------------------------
local journalMappinExtractor = {}

local capturedQuestMappins = {}
local mappinsChangeCounter, prevMappinsChangeCounter, firstTimeRun = 0, 0, true
local unfinishedQuestsRequestContext = nil
local activeQuestsRequestContext = nil

-- Warning: Don't change the functions order as it will break the code execution!

local function resetVariables()
	capturedQuestMappins = {}
	mappinsChangeCounter = 0
	prevMappinsChangeCounter = 0
end

local function setObservers()
	Observe('gamemappinsMappinSystem', 'RegisterMappin', function() --self, data, position)
		mappinsChangeCounter = mappinsChangeCounter + 1
	end)
	
	Observe('gamemappinsMappinSystem', 'SetMappinActive', function() --self, data, position)
		mappinsChangeCounter = mappinsChangeCounter + 1
	end)
	
	Observe('gamemappinsMappinSystem', 'UnregisterMappin', function() --self, id)
		mappinsChangeCounter = mappinsChangeCounter + 1
	end)
	
	ObserveAfter('PlayerPuppet', 'OnGameAttached', function(self)
		if not self:IsReplacer() then
			resetVariables()
		end
	end)	
end

---@param journalEntry gameJournalEntry
---@return string
local function getEntryHash(journalEntry)
	local hash = Game.GetJournalManager():GetEntryHash(journalEntry)

	if hash < 0 then
		hash = hash + 4294967296
	end

	return hash -- ('%08X'):format(hash):sub(-8)
end

local function getDefaulQuestsJournalRequestContext()
	return gameJournalRequestContext.new({
		stateFilter = gameJournalRequestStateFilter.new({
			inactive = true,
			active = true,
			succeeded = true,
			failed = true,
		})
	})
end

local function getUnfinishedQuestsJournalRequestContext()
	return gameJournalRequestContext.new({
		stateFilter = gameJournalRequestStateFilter.new({
			inactive = true,
			active = true,
			succeeded = false,
			failed = false,
		})
	})
end

local function getActiveQuestsJournalRequestContext()
	return gameJournalRequestContext.new({
		stateFilter = gameJournalRequestStateFilter.new({
			inactive = false,
			active = true,
			succeeded = false,
			failed = false,
		})
	})
end

function journalMappinExtractor.init() -- While it is designed to init itself on demand it's recommended to put it in OnInit() handler in the main mod init.lua script.
	if firstTimeRun then
		resetVariables()
		unfinishedQuestsRequestContext = getUnfinishedQuestsJournalRequestContext()
		activeQuestsRequestContext = getActiveQuestsJournalRequestContext()
		setObservers()
	end
	firstTimeRun = false
end

---@param journalData table
local function sortJournalData(journalData)
	table.sort(journalData, function(a, b)
		if a.type ~= b.type then
			return EnumValueFromString('gameJournalQuestType', a.type) < EnumValueFromString('gameJournalQuestType', b.type)
		end

		return a.path < b.path
	end)
end

---@param journalEntries gameJournalEntry[]
function processJournalEntriesForMappinsExtraction(journalEntries, includeMarkers, includeMapIns)
	
	local entryDataList = {}
	local parentData = {}
	if not includeMarkers and not includeMapIns then return entryDataList, parentData end -- just in case... nothing to do if none selected but return a valid data structure
	
	for _, journalEntry in ipairs(journalEntries) do
		local takeIt = false
		local entryData = {id = journalEntry.id, hash = '', path = ''}
		if includeMarkers then
			if journalEntry:IsA('gameJournalQuestGuidanceMarker') then
				---@type gameJournalQuestGuidanceMarker
				local specialEntry = journalEntry

				local globalRef = ResolveNodeRefWithEntityID(specialEntry.nodeRef, GetPlayer():GetEntityID())
				local success, transform = Game.GetNodeTransform(globalRef)

				if success then
					entryData.type = 'Marker'
					entryData.ref = GameDump(specialEntry.nodeRef)
					entryData.pos = transform:GetPosition()
					entryData.hash = getEntryHash(journalEntry)
					table.insert(capturedQuestMappins, {type = entryData.type, id = entryData.id, pos = entryData.pos, ref = entryData.ref, hash = entryData.hash})
				
					takeIt = true
				end

			end
		end

		if includeMapIns then
			if journalEntry:IsA('gameJournalQuestMapPin') then
				---@type gameJournalQuestMapPin
				local specialEntry = journalEntry

				local globalRef = ResolveNodeRefWithEntityID(specialEntry.reference.reference, GetPlayer():GetEntityID())
				local success, transform = Game.GetNodeTransform(globalRef)

				if success then
					entryData.type = 'MapPin'
					entryData.ref = GameDump(specialEntry.reference.reference)
					entryData.pos = transform:GetPosition()
					entryData.hash = getEntryHash(journalEntry)
					table.insert(capturedQuestMappins, {type = entryData.type, id = entryData.id, pos = entryData.pos, ref = entryData.ref, hash = entryData.hash})
				
					takeIt = true
				end
			end
		end

		if journalEntry:IsA('gameJournalContainerEntry') then
			---@type gameJournalContainerEntry
			local containerEntry = journalEntry
			local childrenEntries = containerEntry.entries

			if #childrenEntries > 0 then
				local entries, overrides = processJournalEntriesForMappinsExtraction(childrenEntries, includeMarkers, includeMapIns)

				if #entries > 0 then
					entryData.entries = entries
				end

				for prop, value in pairs(overrides) do
					if type(value) == 'table' then
						if not entryData[prop] then
							entryData[prop] = {}
						end

						for _, item in pairs(value) do
							table.insert(entryData[prop], item)
						end
					else
						entryData[prop] = value
					end
				end

				for _, prop in pairs({ 'entries', 'phases', 'objectives' }) do
					if type(entryData[prop]) == 'table' then
						sortJournalData(entryData[prop])
					end
				end
				takeIt = true
			end
		end

		if takeIt then
			table.insert(entryDataList, entryData)
		end
	end

	return entryDataList, parentData
end

---@param journalFolder gameJournalFolderEntry
local function collectJournalEntries(journalFolder, journalEntryClass, outputList)
	if not outputList then
		outputList = {}
	end

	for _, journalEntry in ipairs(journalFolder.entries) do
		if journalEntry:IsA(journalEntryClass) then
			table.insert(outputList, journalEntry)
		elseif journalEntry:IsA('gameJournalFolderEntry') then
			collectJournalEntries(journalEntry, journalEntryClass, outputList)
		end
	end

	return outputList
end

local function getJournalQuestsMappins(requestContext)
	if not requestContext then requestContext = getUnfinishedQuestsJournalRequestContext() end
	
	local journalManager = Game.GetJournalManager()
	local questEntries = journalManager:GetQuests(requestContext)
	if questEntries then
		capturedQuestMappins = {}
		processJournalEntriesForMappinsExtraction(questEntries, false, true)
	end
	return capturedQuestMappins
end

 -- this the main one to call here or from outside. A "public" equivalent
function journalMappinExtractor.getCurrentQuestsMappins()
	if (prevMappinsChangeCounter ~= mappinsChangeCounter or firstTimeRun) then
		if firstTimeRun then journalMappinExtractor.init() end
		getJournalQuestsMappins(unfinishedQuestsRequestContext)
	end
	prevMappinsChangeCounter = mappinsChangeCounter
	return capturedQuestMappins
end

 -- this the main one to call here or from outside. A "public" equivalent
function journalMappinExtractor.getActiveQuestsMappins()
	if (prevMappinsChangeCounter ~= mappinsChangeCounter or firstTimeRun) then
		if firstTimeRun then journalMappinExtractor.init() end
		getJournalQuestsMappins(activeQuestsRequestContext)
	end
	prevMappinsChangeCounter = mappinsChangeCounter
	return capturedQuestMappins
end

function journalMappinExtractor.getAllJournalQuestEntries()
	local journalManager = Game.GetJournalManager()
	if journalManager then
		local questsFolder = journalManager:GetEntryByString('quests', 'gameJournalPrimaryFolderEntry')
		local questsFolderPhL = journalManager:GetEntryByString('ep1/quests', 'gameJournalPrimaryFolderEntry')
		local questList = collectJournalEntries(questsFolder, 'gameJournalQuest')
		if questsFolderPhL then questList = collectJournalEntries(questsFolderPhL, 'gameJournalQuest', questList) end
		return questList
	end
	return nil
end

return journalMappinExtractor
