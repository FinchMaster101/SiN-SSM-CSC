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
			if(action=="v_brake")then -- start
				if(vehicle.plMode==0)then
					vehicle.plMode=1;
				else
					vehicle.plMode=0;
				end;
			elseif(action=="v_moveforward")then
				if(vehicle.plMode==1)then
					if(activation=="press")then
						printf("Mode=1 | DOWN");
						vehicle.impMode=1;
					else
						vehicle.impMode=nil;	
					end;
				end;
			elseif(action=="v_moveback")then
				if(vehicle.plMode==1)then
					if(activation=="press")then
						printf("Mode=2 | UP");
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
	PL_MODE_UPDATE_DELAY = 0.3;
end;
---------------------------------------------------------------------
if(not PL_MODE_BASE_SPEED)then
	PL_MODE_BASE_SPEED = 10000;
end;
---------------------------------------------------------------------
if(not PL_MODE_DIR_UP)then
	PL_MODE_DIR_UP = 0.5;
end;
---------------------------------------------------------------------
if(not PL_MODE_DIR_DOWN)then
	PL_MODE_DIR_DOWN = 0.5;
end;
---------------------------------------------------------------------
if(PL_MODE_REORIENTATE_VEHICLE==nil)then
	PL_MODE_REORIENTATE_VEHICLE = false;
end;
---------------------------------------------------------------------
if(PL_MODE_USE_PLAYER_DIR==nil)then
	PL_MODE_USE_PLAYER_DIR = false;
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
							local trash;
							if(vehicle.impMode)then
								if(vehicle.impMode==1)then
									dir.z = dir.z - PL_MODE_DIR_DOWN;
								elseif(vehicle.impMode==2)then
									dir.z = dir.z + PL_MODE_DIR_UP;
								end;
							end;
							if(PL_MODE_REORIENTATE_VEHICLE and not PL_MODE_USE_PLAYER_DIR)then
								vehicle:SetDirectionVector(dir);
							end;
							vehicle:AddImpulse(0, vehicle:GetCenterOfMassPos(), dir, PL_MODE_BASE_SPEED, 1);
							vehicle.lastImpulseTime = _time;
							--printf("Impulse added !");
						end;
					end;
				else
					--printf("vehicle not in plMode");
				end;
			else
				--printf("vehicle not found");
			end;
		else
		end;
	else
		--self.lb = self.lb or _time-3
		--if _time -self.lb >=3 then
			--printf("plMode == "..tostring(self.plMode or "nil"))
			--self.lb=_time
		--end
	end;
	--OLD.Player_ClUpdate(self,frameTime)
end
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

System.Log("$9[$4SiN$9] Entities patch installed (1.343)")
