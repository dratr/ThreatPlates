﻿local ADDON_NAME, Addon = ...
local TP = Addon.ThreatPlates

---------------------------------------------------------------------------------------------------
-- Imported functions and constants
---------------------------------------------------------------------------------------------------
local L = Addon.L

local DEBUG = Addon.Meta("version"):find("Alpha") or Addon.Meta("version"):find("Beta")

local function toggleDPS()
  if TidyPlatesThreat.db.profile.optionRoleDetectionAutomatic then
    TP.Print(L["|cff89F559Threat Plates|r: Role toggle not supported because automatic role detection is enabled."], true)
  else
    TidyPlatesThreat.db.char.spec[GetSpecialization()] = false
    TidyPlatesThreat.db.profile.threat.ON = true
    TP.Print(L["-->>|cffff0000DPS Plates Enabled|r<<--"])
    TP.Print(L["|cff89F559Threat Plates|r: DPS switch detected, you are now in your |cffff0000dpsing / healing|r role."])
    Addon:ForceUpdate()
  end
end

local function toggleTANK()
  if TidyPlatesThreat.db.profile.optionRoleDetectionAutomatic then
    TP.Print(L["|cff89F559Threat Plates|r: Role toggle not supported because automatic role detection is enabled."], true)
  else
    TidyPlatesThreat.db.char.spec[GetSpecialization()] = true
    TidyPlatesThreat.db.profile.threat.ON = true
    TP.Print(L["-->>|cff00ff00Tank Plates Enabled|r<<--"])
    TP.Print(L["|cff89F559Threat Plates|r: Tank switch detected, you are now in your |cff00ff00tanking|r role."])
    Addon:ForceUpdate()
  end
end

SLASH_TPTPDPS1 = "/tptpdps"
SlashCmdList["TPTPDPS"] = toggleDPS
SLASH_TPTPTANK1 = "/tptptank"
SlashCmdList["TPTPTANK"] = toggleTANK

local function TPTPTOGGLE()
	if TidyPlatesThreat.db.profile.optionRoleDetectionAutomatic then
		TP.Print(L["|cff89F559Threat Plates|r: Role toggle not supported because automatic role detection is enabled."], true)
	else
		if Addon.PlayerRole == "tank" then
			toggleDPS()
		else
			toggleTANK()
		end
	end
end

SLASH_TPTPTOGGLE1 = "/tptptoggle"
SlashCmdList["TPTPTOGGLE"] = TPTPTOGGLE

local function TPTPOVERLAP()
	if GetCVar("nameplateMotion") == "0" then
		if InCombatLockdown() then
			TP.Print(L["We're unable to change this while in combat"])
		else
			SetCVar("nameplateMotion", 1)
			TP.Print(L["-->>Nameplate Overlapping is now |cffff0000OFF!|r<<--"])
		end
	else
		if InCombatLockdown() then
			TP.Print(L["We're unable to change this while in combat"])
		else
			SetCVar("nameplateMotion", 0)
			TP.Print(L["-->>Nameplate Overlapping is now |cff00ff00ON!|r<<--"])
		end
	end
end

SLASH_TPTPOVERLAP1 = "/tptpol"
SlashCmdList["TPTPOVERLAP"] = TPTPOVERLAP

local function TPTPVERBOSE()
	if TidyPlatesThreat.db.profile.verbose then
		TP.Print(L["-->>Threat Plates verbose is now |cffff0000OFF!|r<<-- shhh!!"])
	else
		TP.Print(L["-->>Threat Plates verbose is now |cff00ff00ON!|r<<--"], true)
	end
	TidyPlatesThreat.db.profile.verbose = not TidyPlatesThreat.db.profile.verbose
end

SLASH_TPTPVERBOSE1 = "/tptpverbose"
SlashCmdList["TPTPVERBOSE"] = TPTPVERBOSE

local function PrintHelp()
	TP.Print(L["Usage: /tptp [options]"], true)
	TP.Print(L["options:"], true)
	TP.Print(L["  legacy-custom-styles    Adds (legacy) default custom styles for nameplates that are deleted when migrating custom nameplates to the current format"], true)
	TP.Print(L["  help                    Prints this help message"], true)
	TP.Print(L["  <no option>             Displays options dialog"], true)
	TP.Print(L["Additional chat commands:"], true)
	TP.Print(L["  /tptpverbose   Toggles addon feedback text"], true)
	TP.Print(L["  /tptptoggle    Toggle Role from one to the other"], true)
	TP.Print(L["  /tptpdps       Toggles DPS/Healing threat plates"], true)
	TP.Print(L["  /tptptank      Toggles Tank threat plates"], true)
	TP.Print(L["  /tptpol        Toggles nameplate overlapping"], true)
end

local function SearchDBForString(db, prefix, keyword)
  for key, value in pairs(db) do
    local search_text = prefix .. "." .. key
    if type(value) == "table" then
      SearchDBForString(db[key], search_text, keyword )
    else
      if string.match(string.lower(search_text), keyword) then
        print (search_text, "=", value)
      end
    end
  end
end

-- Command: /tptp
function TidyPlatesThreat:ChatCommand(input)
	local cmd_list = {}
	for w in input:gmatch("%S+") do cmd_list[#cmd_list + 1] = w end

	local command = cmd_list[1]
	if not command or command == "" then
		TidyPlatesThreat:OpenOptions()
	elseif input == "help" then
		PrintHelp()
	elseif input == "legacy-custom-styles" then
		Addon.RestoreLegacyCustomNameplates()
		--	elseif input == "toggle-view-friendly-units" then
		--		TidyPlatesThreat:ToggleNameplateModeFriendlyUnits()
		--	elseif input == "toggle-view-neutral-units" then
		--		TidyPlatesThreat:ToggleNameplateModeNeutralUnits()
		--	elseif input == "toggle-view-enemy-units" then
		--		TidyPlatesThreat:ToggleNameplateModeEnemyUnits()
	elseif DEBUG then
		if command == "searchdb" then
			TP.Print("|cff89F559Threat Plates|r: Searching settings:", true)
			SearchDBForString(TidyPlatesThreat.db.profile, "<Profile>", string.lower(cmd_list[2]))
			SearchDBForString(TidyPlatesThreat.db.global, "<Profile>", string.lower(cmd_list[2]))
		elseif command == "unit" then
			local plate = C_NamePlate.GetNamePlateForUnit("target")
			if not plate then return end
			Addon.Debug:PrintUnit(plate.TPFrame.unit, true)
		elseif command == "migrate" and cmd_list[2] then
			Addon.MigrateDatabase(cmd_list[2])
		elseif command == "prune" then
			TP.Print("|cff89F559Threat Plates|r: Pruning deprecated data from addon settings ...", true)
			Addon:DeleteDeprecatedSettings()
		elseif input == "event" then
			TP.Print("|cff89F559Threat Plates|r: Event publishing overview:", true)
			Addon:PrintEventService()
		elseif command == "quest" then
			Addon:PrintQuests()
		elseif command == "cache" then
			Addon.DebugPrintCaches()
		elseif command == "guid" then
			local plate = C_NamePlate.GetNamePlateForUnit("target")
			if not plate then return end

			local guid = UnitGUID(plate.TPFrame.unit.unitid)
			local _, _,  _, _, _, npc_id = strsplit("-", guid)

			print(plate.TPFrame.unit.name, " => NPC-ID:", npc_id, "=>", guid)

			local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(C_UIWidgetManager.GetPowerBarWidgetSetID())
			for i, w in pairs(widgets) do
				print (i, w)
			end
		else
			TidyPlatesThreat:ChatCommandDebug(cmd_list)
		end
	else
		TP.Print(L["Unknown option: "] .. input, true)
		PrintHelp()
	end
end

function TidyPlatesThreat:ChatCommandDebug(cmd_list)
	local command = cmd_list[1]
	if command == "combat" and DEBUG then
		local plate = C_NamePlate.GetNamePlateForUnit("target")
		if not plate then return end

		print ("In Combat:", IsInCombat())
		print ("In Combat with Player:", UnitAffectingCombat("target", "player"))
	elseif command == "alpha" then
		local plate = C_NamePlate.GetNamePlateForUnit("target")
		if not plate then return end

		local tp_frame = plate.TPFrame
		local unit = tp_frame.unit

		print("Plate:")
		print("    Alpha:", plate:GetAlpha())
		print("    Scale:", plate:GetScale())
		print("Threat Plate:")
		print("    Showing / Hiding:", tp_frame.IsShowing, "/", tp_frame.HidingScale)
		print("    Alpha:", tp_frame:GetAlpha())
		print("    CurrentAlpha:", tp_frame.CurrentAlpha)
		print("    Scale:", tp_frame:GetScale())
	elseif command == "debug" then
		local plate = C_NamePlate.GetNamePlateForUnit("target")
		if not plate then return end

		local tp_frame = plate.TPFrame
		local unit = tp_frame.unit
		local stylename = tp_frame.stylename
		local nameplate_style = ((stylename == "NameOnly" or stylename == "NameOnly-Unique") and "NameMode") or "HealthbarMode"

		print ("Unit Name:", unit.name)
		print ("Unit Reaction:", unit.reaction)
		print ("Frame Style:", stylename)
		print ("Plate Style:", nameplate_style)
		print ("Color Statusbar:", Addon.Debug:ColorToString(tp_frame.visual.Healthbar:GetStatusBarColor()))
		print ("Color Border:", Addon.Debug:ColorToString(tp_frame.visual.Healthbar.Border:GetBackdropColor()))
	elseif command == "plate" then
		local plate = C_NamePlate.GetNamePlateForUnit("target")
		if not plate then return end

		local tp_frame = plate.TPFrame
		local unit = tp_frame.unit

		local stylename = "dps"
		local style = Addon.Theme[stylename]

		local NAMEPLATE_STYLES_BY_THEME = {
			dps = "HealthbarMode",
			tank = "HealthbarMode",
			normal = "HealthbarMode",
			totem = "HealthbarMode",
			unique = "HealthbarMode",
			empty = "None",
			etotem = "None",
			NameOnly = "NameMode",
			["NameOnly-Unique"] = "NameMode",
		}

		tp_frame.PlateStyle = NAMEPLATE_STYLES_BY_THEME[stylename]
		tp_frame.stylename = stylename
		tp_frame.style = style
		unit.style = stylename

		Addon.Elements.GetElement("Healthbar").UpdateStyle(tp_frame, style)
	elseif command == "unit" then
		local plate = C_NamePlate.GetNamePlateForUnit("target")
		if not plate then return end
		local unit = plate.TPFrame.unit

		Addon.Debug:PrintUnit(unit, true)
    local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", unit.guid)
    print ("GUID:", type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid)
  elseif command == "color" then
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return end
    local unit = plate.TPFrame.unit

    local beginTime = debugprofilestop()
    for i = 1, 100 do
      --
      unit.health = i
      unit.healthmax = 100
      Addon.TestColorByHealth(unit)
      --
    end
    local timeUsed = debugprofilestop()  -beginTime
    print("Ohne Cache: "..timeUsed)

    -- Fill cache
    for i = 1, 100 do
      unit.health = i
      unit.healthmax = 100
      Addon.TestColorByHealthCache(unit)
    end

    local beginTime = debugprofilestop()
    for i = 1, 100 do
      --
      unit.health = i
      unit.healthmax = 100
      Addon.TestColorByHealthCache(unit)
      --
    end
    local timeUsed = debugprofilestop()  -beginTime
    print("Mit Cache: "..timeUsed)
  elseif command == "perf" then

    local plate = C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return end
    local unit = plate.TPFrame.unit
    local unitid = unit.unitid

    local beginTime = debugprofilestop()
    for i = 1, 1000 do
      --
      Addon.TestColorNormal(plate.TPFrame)
      --
    end
    local timeUsed = debugprofilestop()  -beginTime
    print("Normal: "..timeUsed)

    local beginTime = debugprofilestop()
    for i = 1, 1000 do
      --
      Addon.TestColorNormalOpt(plate.TPFrame)
      --
    end
    local timeUsed = debugprofilestop()  -beginTime
    print("Opt : "..timeUsed)
  elseif command == "heuristic" then
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return end
    local unit = plate.TPFrame.unit

    Addon.GetColorByThreat(unit, unit.style, true)

		--print (unit.name, "- InCombatThreat =", unit.InCombatThreat)

		--    print ("Use Threat Table:", TidyPlatesThreat.db.profile.threat.UseThreatTable)
    --    print ("Use Heuristic in Instances:", TidyPlatesThreat.db.profile.threat.UseHeuristicInInstances)

    --print ("InCombat:", InCombatLockdown())

    --Addon:ShowThreatFeedback(unit,true)
    --Addon:GetThreatColor(unit, unit.style, TidyPlatesThreat.db.profile.threat.UseThreatTable, true)
    --Addon:SetThreatColor(unit, true)
  elseif command == "test" then
    local plate = C_NamePlate.GetNamePlateForUnit("target")
    if not plate then return end
    local unit = plate.TPFrame.unit

    plate.PreviousScale = 0
    plate.Time = 0
	elseif command == "anim" then
    local plate = C_NamePlate.GetNamePlateForUnit("mouseover")
    if not plate then return end
    local unit = plate.TPFrame.unit

    Addon.Animations:CreateShrink(plate.TPFrame)
    Addon.Animations:Shrink(plate.TPFrame, 2, 5)
  elseif command == "migrate" then
		Addon.MigrateDatabase(cmd_list[2])
  elseif command == "role" then

    local spec_roles = TidyPlatesThreat.db.char.spec
    for i, is_tank in pairs(spec_roles) do
      print (i, "=", is_tank)
    end

    local spec_roles = self.db.char.spec
    if #spec_roles + 1 ~= GetNumSpecializations() then
      for i = 1, GetNumSpecializations() do
        local is_tank = spec_roles[i]
        if is_tank == nil then
          local id, spec_name, _, _, role = GetSpecializationInfo(i)
          local role = (role == "TANK" and true) or false
          spec_roles[i] = role
          print ("Role", i, " => ", is_tank, " to ", role)
        else
          print ("Role", i, " => ", is_tank)
        end
      end
    end

--
--    for index = 1, GetNumSpecializations() do
--      local id, name, description, icon, role, primaryStat = GetSpecializationInfo(index)
--      --local id, name, description, texture, role, class = GetSpecializationInfoByID(specID);
--      print (name, "(", id, ") =>", role)
--    end
--
--    for i = 1, GetNumClasses() do
--      local _, class, classID = GetClassInfo(i)
--      for j = 1, GetNumSpecializationsForClassID(classID) do
--        local _, spec, _, _, role = GetSpecializationInfoForClassID(classID, j)
--        print (class .. ":", spec, "=>", role)
--      end
--    end

      --		--PrintHelp()
		--	else
--		TP.Print(L["Unknown option: "] .. input, true)
--		PrintHelp()
	elseif command == "db" then
		print ("Searching settings:")
		SearchDBForString(TidyPlatesThreat.db.profile, "<Profile>", string.lower(cmd_list[2]))
	end
end