Aim = {
	cfg = {
		enabled = true;
		logging = {
			logName = "Aim";
			logColor = "$7";
		};
		cvars = {
			consolePrefix = "aim_";
		};
	};
	globals = {
		["aim_enabled"] = true;
		["aim_logVerbosity"] = 1;
		["aim_useAdvanced"] = true;
		["aim_debugVerbosity"] = 0;
		["aim_simpleAimMaxAngles"] = 40;
		["aim_aimBone"] = "pelvis";
		["aim_maxDistance"] = 20;
		["aim_minDistance"] = 2.5;
	};
	lastMap = (Aim ~= nil and Aim.lastMap or "-1");
	temp = {};
	old = (Aim~=nil and Aim.old or {});
	---------------------------
	Init = function(self)
		self:InitGlobals();
		---------------------------
		if(not printf)then 
			printf = function(a,...) 
				 if(not ...)then 
					System.LogAlways(tostring(a)); 
				else 
					System.LogAlways(string.format(tostring(a), ...));
				end;
			end;
		end;
		---------------------------
		if(not print_aim)then 
			print_aim = function(a,...) 
				return printf("$9[$7Aim$9] " .. (a or ""), ...);
			end;
		end;
		---------------------------
		self:PrePatch()
	end;
	---------------------------
	PrePatch = function(self)
		local status = self:PatchScripts();
		if(status == 0)then
			self:Log(0, "$8Patching quened");
			self.patchingQuened = true;
			self:CheckQuene();
		elseif(status == 1)then
			self:Log(0, "$3Patching success");
			if(self.patchingQuened)then
				self.patchingQuened = false;
			end;
		elseif(status == 2)then
			self:Log(0, "$3already patched");
			if(self.patchingQuened)then
				self.patchingQuened = false;
			end;
		end;
		self:InitCVars();
	end;
	---------------------------
	InitCVars = function(self)
	
		local addVarFunc = function(name, stringFunction, help)
			System.AddCCommand(self.cfg.cvars.consolePrefix .. name, stringFunction, help or "no help available");
		end;
		----------------------------
		addVarFunc("lua", [[
			Aim:LoadCode(%%);
		]], "executes a lua script");
		----------------------------
		addVarFunc("reloadFile", [[
			Aim:Reload();
		]], "reloads the AimBot file");
		----------------------------
		addVarFunc("toggle", [[
			Aim:SetVariable("aim_enabled", %1, true, false, false);
		]], "enabled/disables the AimBot");
		----------------------------
		addVarFunc("advancedMode", [[
			Aim:SetVariable("aim_useAdvanced", %1, true, false, false);
		]], "enabled/disables the AimBot advanced mode\nnormal mode will automatically aim at targets that are within simpleAimMaxDegrees °angle, nearest target will be ussed\nadvanced mode requires you to look at a player to make aimbot start aiming at them");
		----------------------------
		addVarFunc("logVerbosity", [[
			Aim:SetVariable("aim_logVerbosity", %1, false, true, true);
		]], "sets the AimBot log verbosity");
		----------------------------
		addVarFunc("simpleAimMaxDegrees", [[
			Aim:SetVariable("aim_simpleAimMaxAngles", %1, false, true, true);
		]], "sets the new degrees to aim at targets");
		----------------------------
		addVarFunc("aimBone", [[
			Aim:SetVariable("aim_aimBone", %1, false, false, false, true);
		]], "sets the bone to aim at");
		----------------------------
		addVarFunc("maxDistance", [[
			Aim:SetVariable("aim_maxDistance", %1, false, true, true);
		]], "sets the new max distance to operate");
		----------------------------
		addVarFunc("minDistance", [[
			--Aim:SetVariable("aim_minDistance", %1, false, true, true);
		]], "sets the new minimum distance to operate");
	end;
	---------------------------
	InitGlobals = function(self)
		local count = 0;
		for name, value in pairs(self.globals or{}) do
			if(_G[tostring(name)] == nil)then
				_G[tostring(name)] = value;
				count = count + 1;
			end;
		end;
		self:Log(2, "Registered " .. count .. " new globals");
	end;
	---------------------------
	RemoveGlobals = function(self)
		local count = 0;
		for name, value in pairs(self.globals or{}) do
			if(_G[tostring(name)] ~= nil)then
				_G[tostring(name)] = nil;
				count = count + 1;
			end;
		end;
		self:Log(2, "Un-Registered " .. count .. " globals");
	end;
	---------------------------
	Reload = function(self, clearData)
		self:Log(0, "Reloading file ... ");
		if(clearData)then
			self:RemoveGlobals();
			Aim = nil;
		end;
		System.ExecuteCommand([[realism ");loadfile("AimBot.lua")();--]]);
	end;
	---------------------------
	LoadCode = function(self, luaCode)
		if(not luaCode)then
			return self:Log(1, "No lua code specified");
		end;
		local success, error = pcall(loadstring(luaCode));
		if(success)then
			return self:Log(1, "Executed code: " .. luaCode);
		elseif(error)then
			return self:Log(1, "Failed Executed code: " .. luaCode .. " (" .. tostring(error) .. ")");
		end;
	end;
	---------------------------
	CheckQuene = function(self)
		if(self.patchingQuened)then
			if(g_localActor)then
				self:PrePatch();
			else
				Script.SetTimer(1000, function()
					self:CheckQuene();
				end);
			end;
		end;
	end;
	---------------------------
	PatchScripts = function(self, skipMapCheck)
		if(not g_localActor)then
			return 0;
		end;
		local currentMap = System.GetCVar("sv_map");
		if(skipMapCheck or (not self.lastMap or currentMap ~= self.lastMap))then -- patch GameRules only once per map, else it will cause overflow!!
			self.lastMap = currentMap;
			self.old._GameRules = SinglePlayer.Client.OnUpdate;
			
			SinglePlayer.Client.OnUpdate = function(GameRules, deltaTime)
				self.old._GameRules(GameRules, deltaTime);
				Aim:DoUpdate(GameRules.class == "PowerStruggle", deltaTime);
			end;
			
		elseif(currentMap == self.lastMap)then
			return 2;
		end;
		return 1;
	end;
	---------------------------
	DoUpdate = function(self, isPowerStruggle, deltaTime)
		self:Log(4, "Updating, deltaTime: " .. deltaTime);
		if(aim_enabled)then 
		
			local distance;
			
			local currentWeapon = g_localActor.inventory:GetCurrentItem();
			
			local maxD, minD = aim_maxDistance, aim_minDistance;
			if(currentWeapon and currentWeapon.class == "Fists")then
				maxD, minD = 4, 1.8;
			end;
		
			if(self.temp._aimEntityId)then
				local AimTarget = System.GetEntity(self.temp._aimEntityId);
				distance = self:GetDistance(AimTarget, g_localActor);
				if(not self:CanSee(AimTarget) or distance > maxD or distance < minD)then
					self:ClearData();
				end;
			end;
			
			
			local isInTeam = false;
					
			if(aim_useAdvanced)then
			
				local dir = System.GetViewCameraDir();
				local hits = Physics.RayWorldIntersection(System.GetViewCameraPos(), { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable);
				local hitData = g_HitTable[1];
				if(hits and hitData and hits>0 and g_localActor.actor:GetHealth() >= 1 and g_localActor.actor:GetSpectatorMode() == 0)then
					if(aim_debugVerbosity >= 2)then
						-- code implementation here :)
					end;
					
					CryAction.PersistantSphere(hitData.pos, 0.02, g_Vectors.v100, "CollDamage", 0.08);
					
					for i,a in pairs(hitData) do
						--self:Log(0,tostring(i).."="..tostring(a))
					end;
					hitData.dist = self:RoundNumber(hitData.dist);
					if(hitData.entity)then
						self.temp._aimEntityId = hitData.entity.id;
						local target = System.GetEntity(self.temp._aimEntityId);
						if(target)then
							distance = self:GetDistance(target, g_localActor);
							isInTeam = g_gameRules.class == "PowerStruggle" and g_gameRules.game:GetTeam(target.id) == g_gameRules.game:GetTeam(g_localActor.id);
							if(target.actor)then
								if(self:WithinAngles(target))then
									if(target.actor:GetHealth() >= 1 and target.actor:GetSpectatorMode() == 0)then
										if(not isInTeam)then
											if(distance < maxD and distance > minD)then
												self:ProcessAimedTarget(target);
											else
												self:ClearData();
											end;
											System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Player: $6" .. target:GetName() .. " $1(HP: $3" .. target.actor:GetHealth() .. "$1, EN: $5" .. target.actor:GetNanoSuitEnergy() .. "$1)", 1, 1, 1, 1);
										else
											self:ClearData();
											System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Team Player: $6" .. target:GetName() .. " $1(HP: $3" .. target.actor:GetHealth() .. "$1, EN: $5" .. target.actor:GetNanoSuitEnergy() .. "$1)", 1, 1, 1, 1);
										end;
									else
										self:ClearData();
										System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | $4Dead$1 " .. (isInTeam and "Team " or "") .. "Player: $6" .. target:GetName() .. " $1(HP: $3" .. target.actor:GetHealth() .. "$1, EN: $5" .. target.actor:GetNanoSuitEnergy() .. "$1)", 1, 1, 1, 1);
									end;
								else
									self:ClearData();
								end;
							elseif(target.vehicle)then
								if(not target.vehicle:IsDestroyed())then
									if(not isInTeam)then
										if(currentWeapon and currentWeapon.class == "LAW")then
											self:ProcessAimedTarget(target);
										end;
										System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Vehicle: " .. target.class, 1, 1, 1, 1);
									else
										local driver = target:GetDriverId();
										if(driver)then
											driver = System.GetEntity(driver);
											System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | " .. driver:GetName() .. "'s Team Vehicle: " .. target.class, 1, 1, 1, 1);
										else
											System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Team Vehicle: " .. target.class, 1, 1, 1, 1);
										end;
									end;
								end;
							elseif(target.weapon)then
								self:ClearData();
								if(target.class:find("Custom"))then
									System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Weapon: " .. target.class .. " (Ammo: " .. (target.Properties.AmmoName or "N/A") .. " Count: " .. (target.Properties.Count or "N/A") ..  ")",  1, 1, 1, 1);
								else
									System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Weapon: " .. target.class .. " (Damage: " .. (target.weapon:GetDamage() or "0") .. ")",  1, 1, 1, 1);
								end;
							else
								self:ClearData();
								System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | Entity: " .. target.class,  1, 1, 1, 1);
							end;
						end;
					elseif(hitData.surface)then
						System.DrawLabel(hitData.pos, 1.1, hitData.dist .. "m | " .. System.GetSurfaceTypeNameById(hitData.surface),  1, 1, 1, 1);
						if(self.temp._aimEntityId)then
							self:ClearData();
						end;
					end;
				elseif(self.temp._aimEntityId)then
					self:ClearData();
				end;
			else --if(not self.temp._aimEntityId)then
			
				
				local closestPlayer, nearestDistance = "nil", maxD;
				
				if(not self.temp._aimEntityId)then
					for i, player in ipairs(System.GetEntitiesByClass("Player")or{}) do --g_gameRules.game:GetPlayers()or{}
						isInTeam = g_gameRules.class == "PowerStruggle" and g_gameRules.game:GetTeam(player.id) == g_gameRules.game:GetTeam(g_localActor.id);
						if(self:WithinAngles(player) and player.id ~= g_localActor.id)then
							if(self:GetDistance(g_localActor, player) < nearestDistance and self:GetDistance(g_localActor, player) > minD)then
								if(self:AliveCheck(player) and not isInTeam)then
									closestPlayer, nearestDistance = player, self:GetDistance(g_localActor, player);
								end;
							end;
						end;
					end;
					if(closestPlayer ~= "nil")then
						self.temp._aimEntityId = closestPlayer.id;
						local tPos = closestPlayer:GetBonePos("Bip01 " .. (aim_aimBone == "random" and "pelvis" or aim_aimBone));
						self:SetCameraTarget(tPos); -- need to face target so ProcessAimedTarget() "CanSee" the target :)
						System.DrawLabel(tPos, 1.1, "Player: " .. closestPlayer:GetName() .. " (HP: " .. closestPlayer.actor:GetHealth() .. ", EN: " .. closestPlayer.actor:GetNanoSuitEnergy() .. ")", 1, 1, 1, 1);
					end;
				else
					local target = System.GetEntity(self.temp._aimEntityId);
					System.DrawLabel(self:GetAimPos(), 1.1, "Player: $5" .. target:GetName() .. " $1(HP: $3" .. target.actor:GetHealth() .. "$1, EN: $5" .. target.actor:GetNanoSuitEnergy() .. "$1)", 1, 1, 1, 1);
					self:ProcessAimedTarget();
				end;
			end;
		end;
	end;
	---------------------------
	RoundNumber = function(self, number)
		return (number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5));
	end;
	---------------------------
	GetAimPos = function(self)
		local dir = System.GetViewCameraDir();
		local hits = Physics.RayWorldIntersection(System.GetViewCameraPos(), { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable);
		local hitData = g_HitTable[1];
		if(hits and hits > 0 and hitData)then
			return hitData.pos;
		else
			return { x= 0, y = 0, z = 0 };
		end;
	end;
	---------------------------
	AliveCheck = function(self, target)
		return (target.actor:GetHealth() >= 1 and target.actor:GetSpectatorMode() == 0);
	end;
	---------------------------
	GetDistance = function(self, a, b)
		local a, b = (a.id and a:GetPos() or a), (b.id and b:GetPos() or b);
		local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
		return math.sqrt(dx * dx + dy * dy + dz * dz);
	end;
	---------------------------
	Dot = function(self, a, b)
		return a.x * b.x + a.y * b.y + a.z * b.z;
	end;
	---------------------------
	Angle = function(self, a, b)
		local dt = self:Dot(a, b)
		local ad = math.sqrt(self:Dot(a, a)) * math.sqrt(self:Dot(b, b))
		return math.acos(dt / ad) * 180 / math.pi;
	end;
	---------------------------
	ProcessAimedTarget = function(self)
		local targetId = self.temp._aimEntityId;
		if(targetId)then
			local target = System.GetEntity(targetId);
			if(self:CanSee(target) and not skipCanSee)then
				local tPos = target:GetPos();
				if(target.vehicle)then
					tPos = target:GetCenterOfMassPos();
				else
					local aimBone = aim_aimBone;
					if(aimBone == "random")then
						local randomBones = {
							"pelvis";
							"head";
							"spine";
						};
						if(not self.randomPickedBone)then
							self.randomPickedBone = randomBones[math.random(#randomBones)];
							self:Log(2, "Bone selection is random, selected random bone: " .. self.randomPickedBone .. " out of " .. self:GetTableNum(randomBones) .. " others");
						end;
						aimBone = self.randomPickedBone;
					end;
					tPos = target:GetBonePos("Bip01 " .. aimBone);
				end;
				self:SetCameraTarget(tPos)
			else
				self:Log(3, "Can't see target, clearing data ... ");
				self:ClearData();
			end;
		end;
	end;
	---------------------------
	GetTableNum = function(self, t)
		local c = 0;
		for i, v in pairs(t or{}) do
			c = c + 1;
		end;
		return c;
	end;
	---------------------------
	ClearData = function(self)
		self.temp._aimEntityId = nil;
		self.randomPickedBone = nil;
	end;
	---------------------------
	SetCameraTarget = function(self, targetPos)
		local currentWeapon = g_localActor.inventory:GetCurrentItem();
		local recoil = 0;
		if(currentWeapon and currentWeapon.class ~= "LAW")then
			recoil = currentWeapon.weapon:GetRecoil();
		end;
		local angles = self:GetAngles(targetPos, System.GetViewCameraPos());
		angles.x = angles.x - recoil/100;
		self:Log(2, "Reducing X by " .. recoil/100)
		g_localActor:SetAngles(angles);
	end;
	---------------------------
	GetAngles = function(self, a, b)
		local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z;
		local dst = math.sqrt(dx * dx + dy * dy + dz * dz);
		local vec = {
			x = math.atan2(dz, dst),
			y = 0, --g_localActor:GetAngles().y, -- for leaning. ;)
			z = math.atan2(-dx, dy)
		};
		return vec;
	end;
	---------------------------
	CanSee = function(self, entity)
		if(entity)then
			local dir = System.GetViewCameraDir();
			local hits = Physics.RayWorldIntersection(System.GetViewCameraPos(), { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_all, g_localActor.id, nil, g_HitTable);
			local hitData = g_HitTable[1];
			if(hits and hitData and hits>0)then
				if(not hitData.entity)then 
					return false;
				end;
				if(hitData.entity.id ~= entity.id)then
					return false;
				end;
				return true;
			end;
		end;
		return false;
	end;
	---------------------------
	WithinAngles = function(self, target)
		bone = bone or "Bip01 head";
		thr = thr or 2;
		local pos = System.GetViewCameraPos(); --g_localActor:GetBonePos(bone);
		local tpos = target:GetBonePos("Bip01 head");
		local npos = target:GetBonePos("Bip01 pelvis");
		tpos = {
			x = (tpos.x + npos.x)/2,
			y = (tpos.y + npos.y)/2,
			z = (tpos.z + npos.z)/2
		};
		local dx, dy, dz = tpos.x - pos.x, tpos.y - pos.y, tpos.z - pos.z;
		local dst = math.sqrt(dx * dx + dy * dy + dz * dz);
		local dir = { x = dx/dst, y = dy/dst, z = dz/dst };
		local hitData = {};  
		local hits = Physics.RayWorldIntersection(pos, { x=dir.x*8192, y=dir.y*8192, z=dir.z*8192 }, 8192, ent_terrain+ent_static+ent_rigid+ent_sleeping_rigid+ent_living, g_localActor.id, nil, hitData);
		local entsBefore = 0;
		
		local maxDeg = aim_simpleAimMaxAngles;
		if(maxDeg == 0)then
		end;
		
		if (hits > 0) then
			for i,v in pairs(hitData) do
				if(v.entity)then
					if v.entity.class=="Player" and v.entity.id==target.id then
						if(entsBefore < thr and self:Angle(dir, System.GetViewCameraDir()) < maxDeg)then
							return true;
						else
							return false;
						end;
					end;
				end;
				entsBefore=entsBefore+1;
			end;
		else
			return false;
		end;
	end;
	---------------------------
	SetVariable = function(self, variable, value, isBool, floorValue, onlyPositive, isString)
		if(not (variable or value))then
			return false;
		end;
		local value = (isString and tostring(value) or tonumber(value));
		if(not value)then
			return self:Log(0, variable .. " = " .. tostring(_G[variable]));
		end;
		if(onlyPositive)then
			if(value < 0)then
				value = 0;
			end;
		end;
		if(floorValue)then
			value = math.floor(value);
		end;
		if(isBool)then
			if(value == 0)then
				value = false;
			else
				value = true;
			end;
		end;
		_G[variable] = value;
		self:Log(0, variable .. " = " .. tostring(_G[variable]));
	end;
	---------------------------
	---------------------------
	---------------------------
	---------------------------
	Log = function(self, verbosity, message, ...)
		if(aim_logVerbosity >= verbosity)then
			print_aim(tostring(message), ...);
		end;
	end;
};

Aim:Init()