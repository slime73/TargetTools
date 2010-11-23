-- written by slime

local gkpc = gkinterface.GKProcessCommand
local getradar = radar.GetRadarSelectionID
local setradar = radar.SetRadarSelection
local objectpos = Game.GetObjectAtScreenPos

-- Targetless compatability
local function hastargetless()
	return assert(function() return targetless end)
end
local function targetless_off()
	if hastargetless() then
		targetless.var.scanlock = true
		targetless.api.radarlock = true
		targetless.var.lock = true
		return true
	end
end
local function targetless_on()
	if hastargetless() then
		targetless.api.radarlock = false
		targetless.var.lock = false
		targetless.var.scanlock = false
		return true
	end
end


TargetTools = {}
TargetTools.ReTarget = {
	target={0,0},
	active=gkini.ReadString("targettools", "retarget", "ON") == "ON",
}


function TargetTools.ReTarget:OnEvent(event, type)
	if not self.active then return end
	if event == "TARGET_CHANGED" and not PlayerInStation() then
		self.target = {getradar()}
	elseif event == "HUD_SHOW" then
		setradar(self.target[1], self.target[2])
	end
end

RegisterEvent(TargetTools.ReTarget, "TARGET_CHANGED")
RegisterEvent(TargetTools.ReTarget, "HUD_SHOW")


function TargetTools.SendTarget(channel)
	if GetTargetInfo() then
		local formatstr = "Targeting %s (%d%%), \"%s\", at %dm"
		local nohealthformatstr = "Targeting %s"
		local name, health, distance, factionid, guild, ship = GetTargetInfo()
		if guild and guild ~= "" then
			name = "["..guild.."] "..name
		end
		local str
		if health then
			str = formatstr:format(Article(ship), math.floor(health*100), name, math.floor(distance))
		else
			str = nohealthformatstr:format(name)
		end
		SendChat(str, channel:upper())
	end
end


function TargetTools.ReadyAtDist(channel)
	if GetTargetInfo() then
		local name, health, distance, factionid, guild, ship = GetTargetInfo()
		SendChat("Ready at ".. math.floor(distance) .."m from \""..name.."\"", channel:upper())
	end
end


function TargetTools.AttackedBy(channel)
	if GetLastAggressor() then
		local node, object = GetLastAggressor()
		local charid = GetCharacterID(node)
		if charid == GetCharacterID() then return end
		SendChat("Under attack by "..Article(GetPrimaryShipNameOfPlayer(charid))..", \""..GetPlayerName(charid).."\" !", channel)
	end
end


RegisterUserCommand("GroupTarget", function() TargetTools.SendTarget("GROUP") end)
RegisterUserCommand("GuildTarget", function() TargetTools.SendTarget("GUILD") end)
RegisterUserCommand("GroupReady", function() TargetTools.ReadyAtDist("GROUP") end)
RegisterUserCommand("GuildReady", function() TargetTools.ReadyAtDist("GUILD") end)
RegisterUserCommand("GroupAttacked", function() TargetTools.AttackedBy("GROUP") end)
RegisterUserCommand("GuildAttacked", function() TargetTools.AttackedBy("GUILD") end)


function TargetTools.GetPlayerIDs(charid)
	if not charid then charid = RequestTargetStats() end
	if not charid then return end
	local nodeid = GetPlayerNodeID(charid)
	local objectid = GetPrimaryShipIDOfPlayer(charid)
	return nodeid, objectid, charid
end


function TargetTools.TargetParent(charid)
	setradar(TargetTools.GetPlayerIDs(charid))
end
RegisterUserCommand("TargetParent", TargetTools.TargetParent)


function TargetTools.TargetTurret(rev) -- this way isn't the best
	local skip = 1
	local nodeid, objectid = getradar()
	if not nodeid then TargetTools.TargetFront() return end
	local childnode, childobject
	if not nodeid then return end
	local repmin, repmax = 1, 400
	if rev then repmin, repmax = repmin*-1, repmax*-1 end
	targetless_off()
	for rep = repmin, repmax, skip do
		setradar(nodeid, objectid+rep)
		childnode, childobject = getradar()
		if childobject ~= objectid then break end
	end
	targetless_on()
	if childobject == objectid then TargetTools.TargetParent() end
end

RegisterUserCommand("TargetNextTurret", TargetTools.TargetTurret)
RegisterUserCommand("TargetPrevTurret", function() TargetTools.TargetTurret(true) end)


function TargetTools.GetLocalObjects(charid)
	if not charid then return end
	local nodeid, objectid = GetPlayerNodeID(charid), GetPrimaryShipIDOfPlayer(charid)
	if not nodeid or not objectid then return end
	local localobjects = {}
	targetless_off()
	setradar(nodeid, objectid)
	while true do
		gkpc("LocalRadarNext")
		local nextnode, nextobject = getradar()
		if not nextnode then break end
		local name, health, dist = GetTargetInfo()
		table.insert(localobjects, {nodeid=nextnode, objectid=nextobject, dist=dist})
	end
	targetless_on()
	return localobjects
end

function TargetTools.TargetFront(targetturret, reverse) -- relatively slow and doesn't catch objects which aren't very big on the screen
	gkpc("RadarNone")
	for y=0.5, 0.45, -0.002 do
		for x=0.5, 0.45, -0.002 do
			if objectpos(x,y) then setradar(objectpos(x,y)) return x,y end
		end
	end
	for y=0.5, 0.55, 0.002 do
		for x=0.5, 0.55, 0.002 do
			if objectpos(x,y) then setradar(objectpos(x,y)) return x,y end
		end
	end
	if targetturret then TargetTools.TargetTurret(reverse, true) end
end
RegisterUserCommand("TargetFront", TargetTools.TargetFront)


function TargetTools.TargetShipType(type)
	type = type:lower()
	local ships = {}
	local function IsShipType(charid)
		if GetPrimaryShipNameOfPlayer(charid) and GetPrimaryShipNameOfPlayer(charid):lower():match(type) then
			local distance = GetPlayerDistance(charid)
			if charid == GetCharacterID() then distance = 10000 end
			if distance then
				table.insert(ships, {distance=distance, node=GetPlayerNodeID(charid), object=GetPrimaryShipIDOfPlayer(charid)})
			end
		end
	end
	ForEachPlayer(IsShipType)
	if not ships[1] then return end
	table.sort(ships, function(a,b) return a.distance < b.distance end)
	setradar(ships[1].node, ships[1].object)
end

RegisterUserCommand("TargetRag", function() TargetTools.TargetShipType("ragnarok") end)
RegisterUserCommand("TargetShip", function(unused, data)
	if data then
		TargetTools.TargetShipType(table.concat(data, " "))
	else
		TargetTools.TargetShipType(".")
	end
end)


function TargetTools.TargetPlayer(name)
	name = name:lower()
	local ships = {}
	local function IsPlayerName(charid)
		if GetPlayerName(charid):lower():match(name) then
			local distance = GetPlayerDistance(charid)
			if charid == GetCharacterID() then distance = 10000 end -- sort last
			if distance then
				table.insert(ships, {distance=distance, node=GetPlayerNodeID(charid), object=GetPrimaryShipIDOfPlayer(charid)})
			end
		end
	end
	ForEachPlayer(IsPlayerName)
	if not ships[1] then return end
	table.sort(ships, function(a,b) return a.distance < b.distance end)
	setradar(ships[1].node, ships[1].object)
end

RegisterUserCommand("TargetPlayer", function(_, data)
	if data then
		TargetTools.TargetPlayer(table.concat(data, " "))
	else
		TargetTools.TargetPlayer(".")
	end
end)


function TargetTools.TargetCargo(type)
	type = type:lower()
	local _name = GetTargetInfo()
	if _name and not _name:lower():match(type) then gkpc("RadarNone") end
	targetless_off()
	local found = false
	repeat
		gkpc("RadarNext")
		local name = GetTargetInfo()
		if not name then
			print("\127ff0000\""..type.."\" is not in range")
			break
		end
		local nodeid, objectid = getradar()
		if nodeid == 2 and name ~= "Asteroid" and name ~= "Ice Crystal" and name:lower():match(type) then
			found = true
		end
	until found
	targetless_on()
end

RegisterUserCommand("TargetCargo", function(_, data)
	if data then
		TargetTools.TargetCargo(table.concat(data, " "))
	else
		TargetTools.TargetCargo(".")
	end
end)


dofile("ui.lua")
