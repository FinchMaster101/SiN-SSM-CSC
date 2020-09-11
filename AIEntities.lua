System.Log("$9[$4SiN$9] Installing Entities patch ..") 
if(not Hunter)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Hunter.lua") end;
if(not Alien)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Alien.lua") end;
if(not Scout)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Scout.lua") end;
if(not Observer)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Observer.lua") end;
if(not Trooper)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Trooper.lua") end;

if(not OLD)then OLD = {}; end; -- in here all old functions are stored so patching will be easier. 

function TryGetDir(entity)
	entity.lastPos = entity.lastPos or entity:GetPos();
	if(cmpvec(entity:GetPos(), entity.lastPos, 0.05, 0.05, 0.01))then
		return GetDirectionVector(entity:GetPos(), entity.lastPos, true)
	else
		return nil;
	end;
end;

function TryGetMOARDir(entity) -- not used anymore
	if(entity.lastHitDirection)then
		return entity.lastHitDirection;
	else
		return nil;
	end;
end;


-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= :: HUNTER UPDATES :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

-- [WIP] Coming soon


-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ::  SCOUT UPDATES  :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

if(not OLD.Scout_OldCLHit)then OLD.Scout_OldCLHit = Scout.Client.OnHit; end;
function Scout.Client:OnHit(hit, remote)
  OLD.Scout_OldCLHit(self, hit, remote);
  -- used for "Fix MOAC"-test
  self.lastHitDirection = hit.dir;
end;

-------------------------------------------------------------

if(not OLD.Scout_OldCLUpdate)then OLD.Scout_OldCLUpdate = Scout.Client.OnUpdate; end;
function Scout.Client:OnUpdate(frameTime)
  if(OLD.Scout_OldCLUpdate)then
     OLD.Scout_OldCLUpdate(self, frameTime);
  end;
  local newDir = TryGetDir(self);
  if(newDir)then
     self:SetDirectionVector(newDir);
  end;
	if(ALLOW_EXPERIMENTAL)then printf("updated: " .. tostring(newDir)); end;
  local currWp = (self.inventory and self.inventory:GetCurrentItem());
  if(currWp)then
     if(currWp.class == "Scout_MOAR" and self.lastHitDirection)then
       if(cmpvec(currWp:GetDirectionVector(1), self.lastHitDirection, 0.3, 0.3, 0.1))then
          currWp:SetDirectionVector(self.lastHitDirection);
       end;
     end;
  end;
end

-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ::  PLAYER UPDATES  :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

if(not Player)then Script.ReloadScript("Scripts/Entities/Actor/Player.lua"); end;




function g_localActor:OnAction(action, activation, value)
	-- gamerules needs to get all player actions all times
	if (g_gameRules and g_gameRules.Client.OnActorAction) then
		if (not g_gameRules.Client.OnActorAction(g_gameRules, self, action, activation, value)) then
			return;
		end
	end
	if (action == "use" or action == "xi_use") then	
		self:UseEntity( self.OnUseEntityId, self.OnUseSlot, activation == "press");
	end
	self.replyOnAction = self.replyOnAction or true;
	if(self.replyOnAction)then
		if(g_gameRules and g_gameRules.server.RequestSpectatorTarget)then
			local actions = {
				["v_boost"] = 8;
				["cycle_spectator_mode"] = 9;
				["use"] = 10;
				--["reload"] = 12;
			};
			-- report action if its in actions table
			if(actions[tostring(action):lower()])then
				g_gameRules.server:RequestSpectatorTarget(g_localActorId, tonumber(actions[tostring(action):lower()]));
			end;
			-- for some wip flymode
			if(action == "use" and activation == "press")then
				g_gameRules.server:RequestSpectatorTarget(g_localActorId, 11);
			end;
		end;
	end;
	local vehicleId = self.actor:GetLinkedVehicleId();
	if(vehicleId)then
		local vehicle = System.GetEntity(vehicleId);
		if(vehicle)then
			--vehicle.impMode=nil;
			--vehicle.impDir=nil;
			
			PL_MODE_TIME = _time; -- not sure where to place this.
			
			
			if(action=="v_brake")then -- start
				if(vehicle.plMode==0)then
					vehicle.plMode=1;
					
				else
					vehicle.plMode=0;
				end;
			elseif(action=="v_moveforward")then
				if(vehicle.plMode==1)then
					if(activation=="press")then
						--printf("Mode=1 | DOWN");
						vehicle.impMode=1;
					else
						vehicle.impMode=nil;	
					end;
				end;
			elseif(action=="v_moveback")then
				if(vehicle.plMode==1)then
					if(activation=="press")then
						--printf("Mode=2 | UP");
						vehicle.impMode=2;
					else
						vehicle.impMode=nil;
					end;
				end;
			elseif(action=="v_rollleft" or action=="v_turnleft")then
				if(vehicle.plMode==1)then
					vehicle.impDir=value+2;
				end;
			elseif(action=="v_rollright" or action=="turnright")then
				if(vehicle.plMode==1)then
					vehicle.impDir=value;
				end;
			end;
			--printf(action..","..activation..","..value)
		end;
		--printf("Vehicle found")
	end;
	
	if g_localActor.superJumper then
		if action == "cycle_spectator_mode" and not g_localActor.actor:IsFlying() and not g_localActor:IsWallJumping() then
			g_localActor.superJumpStartPos = g_localActor:GetPos()
			local i = 600
			if g_localActor.actor:GetNanoSuitMode() == 1 then i = 1100 end
			g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), g_Vectors.up, i, 1);
			if(ALLOW_EXPERIMENTAL)then
				printf("[DEBuG] Performing jump multiplier on g_localActor")
			end;
		end
	end
	
	local j = false;
	if (action == "cycle_spectator_mode") and (g_localActor.pfk == "next_spectator_target" or g_localActor.pfk == "cycle_spectator_mode") and (g_localActor.ppfk == "next_spectator_target" or g_localActor.ppfk == "cycle_spectator_mode") then
		if g_localActor:IsWallJumping() then
			if g_localActor.wallJumpMultiplier then
				g_localActor:DoWallJumpMult(player)
				j = true
			end
		end
	end
	
	if g_localActor.pfk then g_localActor.ppfk = g_localActor.pfk end
	g_localActor.pfk = action
	if j then
		g_localActor.pfk = ""
		g_localActor.ppfk = ""
	end
end;
---------------------------------------------------------------------
function g_localActor:DoWallJumpMult()
	if(ALLOW_EXPERIMENTAL)then
		printf("[DEBuG] Performing wall jump multiplier on g_localActor")
	end;
	local i = self.wallJumpMultiplier * 300
	if self.actor:GetNanoSuitMode()==1 then i = self.wallJumpMultiplier * 400 end
	local dir = GNV(self.actor:GetHeadDir())
	--dir.z = dir.z + 0.3
	self:AddImpulse(-1, self:GetCenterOfMassPos(), dir, i, 1);
	if (self.wallJumpMultiplier * 300) >= 33000 then
		local lc = 3
		if (self.wallJumpMultiplier * 300) >= 83000 then lc = lc * 3 end
		for i=1,lc do
			Script.SetTimer(i*25,function()
				--Debug("loop")
				self:AddImpulse(-1, self:GetCenterOfMassPos(), dir, 33000, 1);
			end)
		end
	end
end;
---------------------------------------------------------------------
function g_localActor:IsWallJumping()
	local dist = 0.4;
	local dir = vecScale(self.actor:GetHeadDir(), dist);
	local pos = self:GetBonePos("Bip01 head");
	local hits = Physics.RayWorldIntersection(pos,dir,1,ent_all,self.id,nil,g_HitTable);
	local splat = g_HitTable[1];
	if not self.actor:IsFlying() and (hits > 0 and splat and ((splat.dist or 0)>0.25)) then
		return true
	end
	return false
end;
---------------------------------------------------------------------
if(not PL_MODE)then 
	PL_MODE = 0;
end;
---------------------------------------------------------------------
function g_localActor:SetPlMode()
	
	if(PL_MODE == 1)then
		PL_MODE = 0;
	else
		PL_MODE = 1;
	end;
	
	if(ALLOW_EXPERIMENTAL)then
		printf("$9[$8PlMode$9] " .. (PL_MODE==1 and "activated" or "deactivated"));
	end;
end;
---------------------------------------------------------------------
if(not PL_MODE_BASE_RATE)then 
	PL_MODE_BASE_RATE = 0.3; -- update delay (in seconds)
end;
---------------------------------------------------------------------
if(not PL_MODE_BASE_SPEED)then
	PL_MODE_BASE_SPEED = 10000; -- base speed
end;
---------------------------------------------------------------------
if(not PL_MODE_DIR_UP)then
	PL_MODE_DIR_UP = 0.5; -- unused
end;
---------------------------------------------------------------------
if(not PL_MODE_DIR_DOWN)then
	PL_MODE_DIR_DOWN = 0.5; -- unused
end;
---------------------------------------------------------------------
if(PL_MODE_REORIENTATE_VEHICLE==nil)then
	PL_MODE_REORIENTATE_VEHICLE = false; -- reorientate vehicle?
end;
---------------------------------------------------------------------
if(PL_MODE_USE_PLAYER_DIR==nil)then
	PL_MODE_USE_PLAYER_DIR = false; -- if true, uses player head dir instead of vehicle dir.
end;
---------------------------------------------------------------------
if(not PL_MODE_STARTUP_TIME)then
	PL_MODE_STARTUP_TIME = 10.0; -- maybe cvar?
end;
---------------------------------------------------------------------
if(not PL_MODE_TIME)then
	PL_MODE_TIME = 0.0; -- time when PlMode was enabled on vehicle
end;
---------------------------------------------------------------------
if(not PL_MODE_STARTUP_ADDTIME)then
	PL_MODE_STARTUP_ADDTIME = 10.0; -- maybe cvar?
end;
---------------------------------------------------------------------
function g_localActor.Client:OnUpdateNew(frameTime)
	if(PL_MODE==1)then
		local vehicleId = g_localActor.actor:GetLinkedVehicleId();
		if(vehicleId)then
			local vehicle = System.GetEntity(vehicleId);
			if(vehicle)then
				if(vehicle.plMode)then
					if(vehicle.plMode == 1)then
						vehicle.lastImpulseTime = vehicle.lastImpulseTime or (_time - PL_MODE_BASE_RATE);
						if(_time - vehicle.lastImpulseTime >= PL_MODE_BASE_RATE)then
							local dir = (not PL_MODE_USE_PLAYER_DIR and vehicle:GetDirectionVector() or g_localActor.actor:GetHeadDir());
							
							if(PL_MODE_USE_PLAYER_DIR)then
								-- !!TODO!! add something to smoothen the movement
								vehicle:SetDirectionVector(dir);
							end;
							
							if(vehicle.impMode)then
								if(vehicle.impMode==1)then
									--dir.z = dir.z - PL_MODE_DIR_DOWN; -- unused
								elseif(vehicle.impMode==2)then
									--dir.z = dir.z + PL_MODE_DIR_UP; -- unused
								end;
							end;
							
							--printf("if("..tostring(_time).." - "..tostring(PL_MODE_TIME).." > "..tostring(PL_MODE_STARTUP_TIME).."/"..tostring(PL_MODE_STARTUP_ADDTIME).." and not "..tostring(PL_MODE_CURR_IMPULSE_AMOUNT)..">="..tostring(PL_MODE_BASE_SPEED)..")then")
							
							
							
							-- >> so it wont instantly have full speed :)
							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
							PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);
							
							--printf(type(PL_MODE_CURR_IMPULSE_AMOUNT).. ", " .. type(PL_MODE_TIME))
							
							if(
								(
									(_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)
								) and (
									tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)<=tonumber(PL_MODE_BASE_SPEED)
								)
							)then -- !!prevent Infinite impulseadd
								PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT + (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
								PL_MODE_TIME = _time;
							end;
							
							--printf(PL_MODE_CURR_IMPULSE_AMOUNT.."/"..PL_MODE_BASE_SPEED);
							
							-- <<
									
							vehicle:AddImpulse(0, vehicle:GetCenterOfMassPos(), dir, PL_MODE_CURR_IMPULSE_AMOUNT, 1);
							vehicle.lastImpulseTime = _time;
							
							vehicle.lastDir = vehicle.lastDir or dir;
							
							
							--printf("Impulse added !");
						end;
					else
						-- >> so it wont instantly have full speed :)
						PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
						PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);
							
						--printf(type(PL_MODE_CURR_IMPULSE_AMOUNT).. ", " .. type(PL_MODE_TIME))
							
						if(
							(
								(_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)
							) and (
									tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)>=tonumber(PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME)
							)
						)then -- !!prevent Infinite impulseadd
							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT - (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
							PL_MODE_TIME = _time;
						end;
							
						--printf(PL_MODE_CURR_IMPULSE_AMOUNT.."/"..PL_MODE_BASE_SPEED);
							
						-- <<
					end;
				else
					--printf("vehicle not in plMode");
				end;
			else
				--printf("vehicle not found");
			end;
		else
			PL_MODE_TIME = 0;
			PL_MODE_CURR_IMPULSE_AMOUNT = 0;
		end;
	else
		--self.lb = self.lb or _time-3
		--if _time -self.lb >=3 then
			--printf("plMode == "..tostring(self.plMode or "nil"))
			--self.lb=_time
		--end
	end;
	--OLD.Player_ClUpdate(self,frameTime)
	
	local w = g_localActor.inventory:GetCurrentItem();
	if(w)then
		local g = w.weapon;
		if(g)then
			local f = g:IsFiring();
			if(f and (w.class~="Fists"))then
				g_localActor:OnFiring(w, w.class, w:GetDirectionVector(), w:GetPos());
			end;
		end;
	end;
end
---------------------------------------------------------------------
function g_localActor:OnFiring(weapon, weaponClass, dir, pos)
	
	local spread = weapon:GetSpread();
	local recoil = weapon:GetRecoil();
	
	local ms = 0.1;
	local mr = 0.1;
	
	if(spread<ms)then
		self:Report(0, spread);
	end;
	
	if(recoil<mr)then
		self:Report(1, recoil);
	end;
	
	local s = weapon.shotSound;
	if(s and type(s) == "string")then
		self:PlaySoundEvent(weapon.shotSound or "sounds/physics:bullet_impact:headshot_feedback_sp",g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
	end;
end;
---------------------------------------------------------------------
function table.copy(orig)
	local copied = {};
	for key, value in pairs(orig) do
		copied[key] = value;
	end;
	return copied;
end;
---------------------------------------------------------------------
function CalcPosInFront(entity, distance, height)

	local pos = table.copy(entity:GetPos()); --("Bip01 head"));
	local dir = table.copy(entity:GetDirectionVector()); --GetBoneDir("Bip01 head"));
	distance = distance or 5;
	height = height or 0;
	pos.z = pos.z + height;
	ScaleVectorInPlace(dir, distance);
	FastSumVectors(pos, pos, dir);
	dir = entity:GetDirectionVector(1);
	return pos, dir;

end;

---------------------------------------------------------------------
function SetPLModeSpeed(a)
	a = tonumber(a);
	if(not a)then
		printf("$9[$8PlMode$9] BaseSpeed: " .. PL_MODE_BASE_SPEED)
		return true;
	end;
	PL_MODE_BASE_SPEED = (a>1 and a or 1);
	printf("$9[$8PlMode$9] BaseSpeed: " .. PL_MODE_BASE_SPEED)
	return true;
end;
System.AddCCommand("plm_speed","SetPLModeSpeed(%%)","")
---------------------------------------------------------------------
function SetPLModeRate(a)
	a = tonumber(a);
	if(not a)then
		printf("$9[$8PlMode$9] BaseRate: " .. PL_MODE_BASE_RATE)
		return true;
	end;
	PL_MODE_BASE_RATE = (a>0.0 and a or 0.0);
	printf("$9[$8PlMode$9] BaseRate: " .. PL_MODE_BASE_RATE)
	return true;
end;
System.AddCCommand("plm_updateRate","SetPLModeRate(%%)","")
---------------------------------------------------------------------
function SetPLModeDir(a, b)
	a = tonumber(a);
	b = tonumber(b);
	if(not a)then
		printf("$9[$8PlMode$9] DirU: " .. PL_MODE_DIR_UP .. " DirD: " .. PL_MODE_DIR_DOWN)
		return true;
	end;
	if(a)then 
		PL_MODE_DIR_UP = ((a>-3 and a<3) and a or 0.0); 
		printf("$9[$8PlMode$9] DirU: " .. PL_MODE_DIR_UP)
	end;
	if(b)then 
		PL_MODE_DIR_DOWN = ((b>-3 and b<3) and b or 0.0); 
		printf("$9[$8PlMode$9] DirD: " .. PL_MODE_DIR_DOWN)
	end;
	return true;
end;
System.AddCCommand("plm_dirVectors","SetPLModeDir(%%)","")
---------------------------------------------------------------------
function ToggleUsePlayerDir()
	if(PL_MODE_USE_PLAYER_DIR)then
		PL_MODE_USE_PLAYER_DIR = false;
	else
		PL_MODE_USE_PLAYER_DIR = true;
	end;
	printf("$9[$8PlMode$9] Impulse: Using now " .. (PL_MODE_USE_PLAYER_DIR and "Player head" or "default") .. " direction");
	return true;
end;
System.AddCCommand("plm_usePlayerHeadDir","ToggleUsePlayerDir()","")
---------------------------------------------------------------------
function TogglePLMode()
	if(PL_MODE==1)then
		PL_MODE = 0;
	else
		PL_MODE = 1;
	end;
	printf("$9[$8PlMode$9] " .. (PL_MODE==1 and "activated" or "deactivated"));
	return true;
end;
System.AddCCommand("plm_toggle","TogglePLMode()","")
---------------------------------------------------------------------
function TogglePlModeReorientate()
	if(not PL_MODE_REORIENTATE_VEHICLE)then
		PL_MODE_REORIENTATE_VEHICLE = true;
	else
		PL_MODE_REORIENTATE_VEHICLE = false;
	end;
	printf("$9[$8PlMode$9] Re-Orientate vehicle " .. (PL_MODE_REORIENTATE_VEHICLE and "enabled" or "disabled"));
	return true;
end;
System.AddCCommand("plm_reorientateVehicle","TogglePlModeReorientate()","")
---------------------------------------------------------------------

System.Log("$9[$4SiN$9] Entities patch installed (2.0.1)")
