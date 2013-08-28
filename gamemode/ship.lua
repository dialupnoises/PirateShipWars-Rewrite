

PSW.ShipData = {}
PSW.ShipData[TEAM_RED] = {}
PSW.ShipData[TEAM_RED].name = "Red"
PSW.ShipData[TEAM_RED].countdown = 35
PSW.ShipData[TEAM_BLUE] = {}
PSW.ShipData[TEAM_BLUE].name = "Blue"
PSW.ShipData[TEAM_BLUE].countdown = 35

Ships = {}

function Ships.SpawnShips()
	for k, v in pairs(ents.FindByName("spawnbutton")) do
		v:Fire("Press", "", 0)
	end
	PSW.ShipData[TEAM_RED].sinking = false
	PSW.ShipData[TEAM_RED].disabled = false
	PSW.ShipData[TEAM_BLUE].sinking = false
	PSW.ShipData[TEAM_BLUE].disabled = false
	PSW.Starting = true

	timer.Simple(4, Ships.GetParts)
	timer.Simple(30, function() PSW.Starting = true end)
end

function Ships.GetParts()
	for v = 1, 2 do
		PSW.ShipData[v][3] = part("ship" .. v .. "bottom2left");
		PSW.ShipData[v][4] = part("ship" .. v .. "bottom2right");
		PSW.ShipData[v][5] = part("ship" .. v .. "bottom3left");
		PSW.ShipData[v][6] = part("ship" .. v .. "bottom3right");
		PSW.ShipData[v][8] = part("ship" .. v .. "bottom4right");
		PSW.ShipData[v][9] = part("ship" .. v .. "keel2");
		PSW.ShipData[v][11] = part("ship" .. v .. "sinker2");

		PSW.ShipData[v][13] = part("ship" .. v .. "polefront");
		PSW.ShipData[v][14] = part("ship" .. v .. "mastfront");
		PSW.ShipData[v][15] = part("ship" .. v .. "mastback");
		PSW.ShipData[v][16] = part("ship" .. v .. "door");
		PSW.ShipData[v][17] = part("ship" .. v .. "explosive");
		PSW.ShipData[v][18] = part("ship" .. v .. "keel");

		PSW.ShipData[v][3]:EnableDrag(false);
		PSW.ShipData[v][4]:EnableDrag(false);
		PSW.ShipData[v][5]:EnableDrag(false);
		PSW.ShipData[v][6]:EnableDrag(false);
		PSW.ShipData[v][8]:EnableDrag(false);
		PSW.ShipData[v][9]:EnableDrag(false);
		PSW.ShipData[v][11]:EnableDrag(false);

		PSW.ShipData[v][13]:EnableDrag(false);
		PSW.ShipData[v][14]:EnableDrag(false);
		PSW.ShipData[v][15]:EnableDrag(false);
		PSW.ShipData[v][16]:EnableDrag(false);
		PSW.ShipData[v][17]:EnableDrag(false);
		PSW.ShipData[v][18]:EnableDrag(false);

		PSW.ShipData[v][3]:SetMass(40000);
		PSW.ShipData[v][4]:SetMass(40000);
		PSW.ShipData[v][5]:SetMass(40000);
		PSW.ShipData[v][6]:SetMass(40000);
		PSW.ShipData[v][8]:SetMass(35000);

		local barrel = part("ship" .. v .. "explosive", true)
		if barrel:GetModel() == "models/props_c17/oildrum001_explosive.mdl" then
			barrel:SetModel("models/props_c17/woodbarrel001.mdl")
		end

		if GetConVar("psw_nodoors"):GetBool() then
			ents.GetByName("ship" .. v .. "door", true):Remove()
			ents.GetByName("ship" .. v .. "barrelexplode", true):Remove()
			ents.GetByName("ship" .. v .. "explosive", true):Remove()
			ents.GetByName("s" .. v .. "smoke", true):Remove()
		end
	end
end

function Ships.TakeDamage(ent, info)
	local caller = info:GetInflictor()
	local attacker = info:GetAttacker()
	local amount = info:GetDamage()
	if ent:IsPlayer() then return false end
	
	if attacker:IsPlayer() and string.find(ent:GetName(), "ship") then
		if attacker:Team() == TEAM_RED and string.find(ent:GetName(), "ship1") then return false end
		if attacker:Team() == TEAM_BLUE and string.find(ent:GetName(), "ship2") then return false end
		if ent:GetClass() ~= "prop_physics_multiplayer" and ent:GetClass() ~= "func_breakable" then
			return false
		end
		if PSW.Starting then return false end
	end

	local phys = ent:GetPhysicsObject()
	local owner = ents.GetOwner(ent)

	checkMasts = {"polefront", "mastfront", "mastback"}
	removeEnt = {"weldpolefront", "weldmastfront", "weldpoleback"}
	mastNames = {"polebreak", "mainbreak", "rearbreak"}
	if owner then
		for v = 1, 3 do
			if ent:GetName() == "ship" .. owner .. checkMasts[v] then
				if string.find(caller:GetClass(), "func_physbox") and ents.GetByName("ship" .. owner .. removeEnt[v]) then
					ents.GetByName("ship" .. owner .. removeEnt[v]):Fire("Break", "", 1)
					mastid = "s" .. owner .. mastNames[v]
					ships.CheckMasts(mastid, owner)
				end
			end
		end
		if string.find(ent:GetName(), "ship" .. owner .. "explosive") then
			Ships.Disable(owner)
		elseif string.find(ent:GetName(), "ship") then
			if IsValid(ent) and ent:GetMass() > amount + 5 then
				ent:SetMass(ent:GetMass() - amount)
			else
				ent:SetMass(5)
			end
			Ships.CheckSink(owner)
		end
	end
end
hook.Add("EntityTakeDamage", "detectShipBreakage", Ships.TakeDamage)

function Ships.Disable(t)
	if not PSW.ShipData[t].disabled then
		player.BroadcastMessage(string.upper(PSW.ShipData[t].name) .. " PIRATE SHIP DISABLED")
		PSW.ShipData[t].disabled = true
		local thrusters = {"backwardthruster", "forwardthruster", "rightthruster", "leftthruster", "forwardthruster1"}
		for k, v in pairs(thrusters) do
			for i, l in pairs(ents.FindByName("ship" .. t .. v)) do
				l:Remove()
			end
		end
	end
end

function Ships.CheckMasts(mastid, owner)
	removeMasts = {"polefront", "mastfront", "mastback"}
	mastNames = {"polebreak", "mainbreak", "rearbreak"}
	for v = 1, 3 do
		if mastid == "s" .. owner .. mastNames[v] and not PSW.Starting then
			ents.GetByName("ship" .. owner .. removeMasts[v]):Fire("Kill", "", 0)
			teamropes = ents.FindByName("ship" .. owner .. "rope")
			for k, v in pairs(teamropes) do
				v:Remove()
			end
		end
	end
end

function Ships.CheckSink(owner)
	if not PSW.ShipData[owner].sinking then
		if PSW.ShipData[owner][8] ~= nil && PSW.ShipData[owner][8]:GetMass() > 9000 then
			PSW.ShipData[owner][8]:SetMass(PSW.ShipData[owner][8]:GetMass() - 1000)
			if PSW.ShipData[owner][11]:GetMass() < 40000 then
				PSW.ShipData[owner][11]:SetMass(PSW.ShipData[owner][11]:GetMass() + 2000)
			end
		end
		if PSW.ShipData[owner][3] ~= nil && PSW.ShipData[owner][3]:GetMass() > 2000 then
			PSW.ShipData[owner][3]:SetMass(PSW.ShipData[owner][3]:GetMass() - 1000)
			PSW.ShipData[owner][4]:SetMass(PSW.ShipData[owner][4]:GetMass() - 1000)
			PSW.ShipData[owner][5]:SetMass(PSW.ShipData[owner][5]:GetMass() - 1000)
			PSW.ShipData[owner][6]:SetMass(PSW.ShipData[owner][6]:GetMass() - 1000)
		else
			Ships.Disable(owner)
			if PSW.ShipData[owner][3] ~= nil && PSW.ShipData[owner][3]:GetMass() > 14000 then
				PSW.ShipData[owner][8]:SetMass(1000)
				PSW.ShipData[owner][9]:SetMass(25000)
				PSW.ShipData[owner][3]:SetMass(PSW.ShipData[owner][3]:GetMass() - 1000)
				PSW.ShipData[owner][4]:SetMass(PSW.ShipData[owner][4]:GetMass() - 1000)
				PSW.ShipData[owner][5]:SetMass(1000)
				PSW.ShipData[owner][6]:SetMass(1000)
				PSW.ShipData[owner][11]:SetMass(15000)
			else
				if not PSW.ShipData[opposingTeam(owner)].sinking then
					PSW.ShipData[owner].countdown = 35
					PSW.ShipData[owner].sinking = true
					timer.Create("SinkTimer", 1, PSW.ShipData[owner].countdown, function() Ships.SinkingCountdown(owner) end)
					PSW.AnnounceWinner()
				end
			end
		end	
	end
end

function Ships.SinkingCountdown(owner)
	if PSW.ShipData[owner].countdown == 30 then
		canSpawn = false
	elseif PSW.ShipData[owner].countdown == 7 and PSW.ShipData[v].sinking then
		for k,v in pairs(player.GetAll()) do
			v:StripWeapons()
			v:Spectate(OBS_MODE_ROAMING)
			v:SetTeam(TEAM_SPECTATE)
			v:CrosshairDisable()
		end
	elseif PSW.ShipData[owner].countdown == 5 and PSW.ShipData[owner].sinking then
		spawnShips()
	elseif PSW.ShipData[owner].countdown == 1 then
		currentRound = currentRound + 1
		if currentRound == GetConVarNumber("psw_rounds") then
			player.BroadcastMessage("Last round before map change!")
		end
		if currentRound == GetConVarNumber("psw_rounds") + 1 then
			player.BroadcastMessage("Changing map!")
			Msg("Changing map")
			local changeMap = hook.Call("PSWChangeMap") -- should return true if it exists
			if not changeMap then timer.Simple(1, game.LoadNextMap) end
		end
		team.AddScore(team.GetOpposing(owner), 30)
		timer.Remove("SinkTimer")
		canSpawn = true

		for k,v in pairs(player.GetAll()) do
			v:UnSpectate()
			v:KillSilent()
			v:Respawn()
			v:ConCommand("r_cleardecals")
			v:PrintMessage(HUD_PRINTCENTER, "Sink the enemy pirate ship!")
		end
	end

	PSW.ShipData[owner].countdown = PSW.ShipData[owner].countdown - 1

	--very confusing if statement
	if PSW.ShipData[owner].sinking then
		if PSW.ShipData[owner][3]:GetMass() > 400 then
			PSW.ShipData[owner][3]:SetMass( PSW.ShipData[owner][3]:GetMass() - 200 )
			PSW.ShipData[owner][4]:SetMass( PSW.ShipData[owner][4]:GetMass() - 200 )
		end	

		PSW.ShipData[owner][8]:SetMass(1000)

		if PSW.ShipData[owner][11]:GetMass() <= 40000 then		
			PSW.ShipData[owner][5]:SetMass(500);
			PSW.ShipData[owner][6]:SetMass(500);
			PSW.ShipData[owner][11]:SetMass( PSW.ShipData[owner][11]:GetMass() + 1000 ); 
		end

		if PSW.ShipData[owner][11]:GetMass() > 40000 then
			PSW.ShipData[owner][5]:SetMass(1000)
			PSW.ShipData[owner][6]:SetMass(1000)
			if PSW.ShipData[owner][9]:GetMass() > 2000 then
				PSW.ShipData[owner][9]:SetMass(PSW.ShipData[owner][9]:GetMass()-1000)
			end
		elseif PSW.ShipData[owner][11]:GetMass() > 49000 then
			PSW.ShipData[owner][10]:SetMass(35000)
			PSW.ShipData[owner][9]:SetMass(2000)
			PSW.ShipData[owner][3]:SetMass(1000)
			PSW.ShipData[owner][4]:SetMass(1000)	
		end
	end
end

function opposingTeam(plyteam)
	if plyteam == TEAM_RED then
		return TEAM_BLUE
	else
		return TEAM_RED
	end
end

function part(name)
	local ent = ents.GetByName( name )
	if ( ent ) then 
		return ent
	end
end