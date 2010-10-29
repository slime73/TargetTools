local gkpc = gkinterface.GKProcessCommand
local getradar = radar.GetRadarSelectionID
local setradar = radar.SetRadarSelection
local objectpos = Game.GetObjectAtScreenPos


TargetTools = {ReTarget={target={0,0}, active=gkini.ReadString("targettools", "retarget", "ON")=="ON"}}


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
		local formatstr = "Targeting %s (%d), \"%s\", at %dm"
		local nohealthformatstr = "Targeting %s"
		local name, health, distance, factionid, guild, ship = GetTargetInfo()
		local str = health and formatstr:format(Article(ship), math.floor(health*100), name, math.floor(distance)) or formatstr:format(name)
		SendChat(str, channel:upper())
	end
end


function TargetTools.ReadyAtDist(channel)
	if GetTargetInfo() then
		local name, health, distance = GetTargetInfo()
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
	for rep = repmin, repmax, skip do
		setradar(nodeid, objectid+rep)
		childnode, childobject = getradar()
		if childobject ~= objectid then break end
	end
	if childobject == objectid then TargetTools.TargetParent() end
end


--[[function TargetTools.TargetTurret(rev, stop) -- doesn't work :(
	if stop then return end
	local node, object = getradar()
	if not node then TargetTools.TargetFront(true, rev) return end
	gkpc(rev and "LocalRadarPrev" or "LocalRadarNext")
	local nextnode, nextobject = getradar()
	if not nextnode then
		local parentobject = GetPrimaryShipIDOfPlayer(GetCharacterID(node))
		parentobject = parentobject or object
		setradar(node, parentobject)
	end
end]]

RegisterUserCommand("TargetNextTurret", TargetTools.TargetTurret)
RegisterUserCommand("TargetPrevTurret", function() TargetTools.TargetTurret(true) end)


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
			if charid == GetCharacterID() then distance = 10000 end
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

RegisterUserCommand("TargetPlayer", function(unused, data)
	if data then
		TargetTools.TargetPlayer(table.concat(data, " "))
	else
		TargetTools.TargetPlayer(".")
	end
end)


function TargetTools.TargetCargo(type)
	type = type:lower()
	local timer = Timer()
	if GetTargetInfo() and not GetTargetInfo():lower():match(type) then gkpc("RadarNone") end
	local function nextcargo()
		gkpc("RadarNext")
		local name = GetTargetInfo()
		if not name then return elseif name:lower():match(type) then return end
		timer:SetTimeout(10)
	end
	timer:SetTimeout(1, nextcargo)
end

RegisterUserCommand("TargetCargo", function(_, data)
	if data then
		TargetTools.TargetCargo(table.concat(data, " "))
	else
		TargetTools.TargetCargo(".")
	end
end)


local loadedtext = "*** TargetTools loaded."

function TargetTools:OnEvent(event, data, ...)
	if event == "PLAYER_ENTERED_GAME" then
		purchaseprint(loadedtext)
		UnregisterEvent(self, "PLAYER_ENTERED_GAME")
	end
end
RegisterEvent(TargetTools, "PLAYER_ENTERED_GAME")


dofile("ui.lua")
