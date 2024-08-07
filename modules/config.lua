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

-- Oct 25, 2023 based on the (c)keanuWheeze original script modified by (c)anygoodname by the keanuWheeze consent

config = {
	modVer = 'v3.2.4',
	moduleVer = 'v3.1.17',
	modName = 'Autoloot',
	modAuthorName = 'keanuWheeze and anygoodname',
}

function loadModSettings(filename, currentSettings)
	if type(currentSettings) ~= 'table' then return end
	if type(filename) ~= 'string' then return end
	if string.len(filename) < 6 then return end
	local file = io.open(filename, "r")
	if file then
		local jString = file:read("*a")
		file:close()
		if type(jString) ~= 'string' then return end
		local loadedSettings
		pcall(function() loadedSettings = json.decode(jString) end)
		if type(loadedSettings) == 'table' then
			local output = {}
			local isAnythingMissing = false
			for varName, value in pairs(currentSettings) do if type(loadedSettings[varName]) == type(value) then output[varName] = loadedSettings[varName] else output[varName] = currentSettings[varName] isAnythingMissing = true end end
			if type(output.customTriggerKbdDelay) == 'number' then output.customTriggerKbdDelay = ClampF(output.customTriggerKbdDelay, 0, 2) else output.customTriggerPadDelay = 0 end
			if type(output.customTriggerPadDelay) == 'number' then output.customTriggerPadDelay = ClampF(output.customTriggerPadDelay, 0, 2) else output.customTriggerPadDelay = 0 end
			if isAnythingMissing then saveModSettings(filename, output) end
			return true, output
		end
	else
		saveModSettings(filename, currentSettings)
	end
end

function saveModSettings(filename, settings)
	if type(filename) ~= 'string' then return end
	if type(settings) ~= 'table' then return end
	if string.len(filename) < 6 then return end
	local file = io.open(filename, "w")
	if file then
		local jString = json.encode(settings)
		file:write(jString)
		file:close()
	end
end

function config.loadConfig(path, currentSettings)
	local result, loadedData = loadModSettings(path, currentSettings)
	if not result then return currentSettings end
	return loadedData
end

function config.saveConfig(path, data) -- it's just a wrapper now
	return saveModSettings(path, data)
end

return config