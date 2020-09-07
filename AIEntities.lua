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


-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= :: HUNTER UPDATES :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

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
			if(action=="v_moveforward")then
				if(activation=="press")then
					vehicle.plMode = 1	
				else
					vehicle.plMode = 0;
				end;
				printf("mode set to " .. vehicle.plMode)
			end;
		end;
		--printf("Vehicle found")
	end;
end;



--if(not OLD.Player_ClUpdate)then OLD.Player_CLUpdate = g_localActor.Client.OnUpdate; end;
function g_localActor.Client:OnUpdateNew(frameTime)
	if(self.plMode~=nil)then
		local vehicleId = self.actor:GetLinkedVehicleId();
		if(vehicleId)then
			local vehicle = System.GetEntity(vehicleId);
			if(vehicle)then
				if(vehicle.plMode)then
					if(vehicle.plMode == 1)then
						vehicle.lastImpulseTime = vehicle.lastImpulseTime or (_time - 0.3);
						if(_time - vehicle.lastImpulseTime >= 0.3)then
							vehicle:AddImpulse(0, vehicle:GetPos(), vehicle:GetDirectionVector(1), 100000, 1);
							vehicle.lastImpulseTime = _time;
							printf("Impulse added !")
						end;
					end;
				end;
			end
		else
		end;
	else
		printf("plMode == "..self.plMode)
	end;
	--OLD.Player_ClUpdate(self,frameTime)
end


System.Log("$9[$4SiN$9] Entities patch installed (1.01)")
