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

-- THIS MODULE CAN BE TRANSLATED AND REPUBLISHED AS A TRANSLATION MOD.

-- Oct 25, 2023 based on the (c)keanuWheeze original script modified by (c)anygoodname by the keanuWheeze consent

-------------

ui = {
		modVer = 'v3.2.4',
		moduleVer = 'v3.1.11',
		modName = 'Autoloot',
		modAuthorName = 'keanuWheeze and anygoodname',
		isInitialized = false
	}

function ui.draw(autoLoot)
    if autoLoot.CPS then autoLoot.CPS.setThemeBegin() end
	if (ImGui.Begin("AutoLoot", ImGuiWindowFlags.AlwaysAutoResize)) then
		pcall(function()
			if ui.isInitialized then
				ImGui.Spacing()

				if type(autoLoot.settings.range) ~= 'number' then autoLoot.settings.range = 1000 end
				autoLoot.settings.range, changed = ImGui.SliderInt("Range", autoLoot.settings.range, 1, 1000)
				if changed then
					autoLoot.config.saveConfig("config/config.json", autoLoot.settings)
				end
				ImGui.TextWrapped("This sets the maximum range for the auto loot")

				ImGui.Spacing()
				ImGui.Separator()
				ImGui.Spacing()

				if type(autoLoot.settings.useDefaultActionKey) ~= 'boolean' then autoLoot.settings.useDefaultActionKey = false end
				autoLoot.settings.useDefaultActionKey, changed = ImGui.Checkbox("Use the game default action key.", autoLoot.settings.useDefaultActionKey)
				if changed then
					autoLoot.config.saveConfig("config/config.json", autoLoot.settings)
				end
				ImGui.TextWrapped("This enables the auto loot on the game default action key press.\nWarning: beware of the Midas golden touch syndrome!")
				ImGui.Spacing()

				if type(autoLoot.settings.showDebugMonitorWindow) ~= 'boolean' then autoLoot.settings.showDebugMonitorWindow = false end
				autoLoot.settings.showDebugMonitorWindow, changed = ImGui.Checkbox("Show Monitor window.", autoLoot.settings.showDebugMonitorWindow)
				if changed then
					autoLoot.config.saveConfig("config/config.json", autoLoot.settings)
				end
				ImGui.TextWrapped("This enables a small monitor window showing the current autolooting state.")
				ImGui.Spacing()

				ImGui.Separator()
				ImGui.TextWrapped(ui.modName..' '..ui.modVer)
			else
				ImGui.Spacing()

				ImGui.TextWrapped("The mod is disabled due to corrupted mod files or incompatibility with the current game version.")
				ImGui.Spacing()

				ImGui.Separator()
				ImGui.Text(ui.modName..' '..ui.modVer..'            ')
			end
		end)
	end
	if autoLoot.CPS then autoLoot.CPS.setThemeEnd() end
    ImGui.End()
end

return ui