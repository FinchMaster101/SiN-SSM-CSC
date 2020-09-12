System.Log("$9[$4SiN$9] Installing Entities patch ..") 

FILE_VERSION = "2.5.2";

if(not Hunter)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Hunter.lua") end;
if(not Alien)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Alien.lua") end;
if(not Scout)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Scout.lua") end;
if(not Observer)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Observer.lua") end;
if(not Trooper)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Trooper.lua") end;

if(not OLD)then OLD = {}; end; -- in here all old functions are stored so patching will be easier. 

SiN= {
	OnEvent = function(self, ent, event)
		event = tostring(event)
		if(not event or event=="nil")then
			Debug(6, "Invalid event to OnEvent")
			return
		end;
		ent = System.GetEntityByName(ent)
		if(not ent)then
			Debug(6, "Invalid entity to OnEvent")
			return;
		end;
		if(ent)then
			if(event=="10")then
				ent.FLY_SLOT = ent:LoadParticleEffect(-1,"smoke_and_fire.Vehicle_fires.burning_jet",{Scale=0.5});
				ent:SetSlotWorldTM(ent.FLY_SLOT, ent:GetPos(), g_Vectors.down);
				Debug(6, "OnEvent:10: loading FlyMode effect on " .. ent:GetName())
			elseif(event=="11")then
				if(ent.FLY_SLOT)then
					ent:FreeSlot(ent.FLY_SLOT);
				end;
				Debug(6, "OnEvent:10:Removing flymode effect")
			end;
			Debug(6, "OnEvent " .. event);
		end;
	end;
	OnKill = function(self, p, s, w, d, m, j)
		local player, shooter = System.GetEntity(p), System.GetEntity(s);
		if(player and shooter)then
			local i = player.lastHitInfo;
			if(i)then
				player:AddImpulse(i.part, i.pos, i.dir, math.min(1000,i.dmg*30), 1);
			end;
		end;
	end;
	ToServ = function(self, num)
		g_gameRules.server:RequestSpectatorTarget(g_localActorId, num);
		Debug(8, "ToServ: " .. num);
	end;
	Update = function(self)
		if(self.UpdateFlyMode)then
			self:UpdateFlyMode()
		end;
	end;
	OnAction = function(self, a, b, c)
		if(a=="use" and g_localActor.hasFlyMode and g_localActor.actor:IsFlying())then
			if(b=="press")then
				self:FlyMode(1)
			else
				self:FlyMode(0)
			end;
		end;
	end;
	UpdateFlyMode = function(self)
		DebugT(16, "Updating FlyMode: " .. tostring(g_localActor.flyMode) .. " " .. tostring(g_localActor.flyMode==1))
		
		if(g_localActor.flyMode and g_localActor.flyMode == 1)then
			if(g_localActor.actor:GetHealth()>0 and not g_localActor.actor:GetLinkedVehicleId() and g_localActor.actor:IsFlying())then
				local imp = 30;
				local cd = System.GetViewCameraDir()
				if(cd.z < -0.8)then
					cd.z=cd.z+0.5	
				end;
				g_localActor:AddImpulse(-1, g_localActor:GetCenterOfMassPos(), cd, imp, 1)
				Debug(20, "FlyMode: Adding impulse " .. imp)
			else
				self:FlyMode(0)
			end;
		end;	
	end;
	FlyMode = function(self, mode)
		g_localActor.flyMode = mode;
		Debug(8, "FlyMode set to " .. mode)
		self:ToServ((mode==1 and 15 or 16))
	end;
};

function TryGetDir(entity)
	entity.lastPos = entity.lastPos or entity:GetPos();
	if(cmpvec(entity:GetPos(), entity.lastPos, 0.05, 0.05, 0.01))then
		return GetDirectionVector(entity:GetPos(), entity.lastPos, true)
	else
		return nil;
	end;
end;

function GetVectorDistance(a, b)

	local p1, p2 = (not a.id and a or a:GetWorldPos()), (not b.id and b or b:GetWorldPos());

	local x, y, z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);

	return (math.sqrt(x*x + y*y + z*z) or 0.0)

end;

function TryGetMOARDir(entity) -- not used anymore
	if(entity.lastHitDirection)then
		return entity.lastHitDirection;
	else
		return nil;
	end;
end;

LOG_VERBOSITY = LOG_VERBOSITY or 0;

function Debug(v, m)
	if(LOG_VERBOSITY>=v)then
		printf("[DEBuG] " .. tostring(m));
	end;
end;

function DebugT(v, m)
	LAST_DEBUG = LAST_DEBUG or _time - 1;
	if(LOG_VERBOSITY>=v and _time - LAST_DEBUG >=1 )then
		printf("[DEBuG] " .. tostring(m));
		LAST_DEBUG = _time;
	end;
end;

function SetDebugVerbosity(a)
	a = tonumber(a);
	if(not a)then
		printf("    $3debug_logVerbosity = $7" .. LOG_VERBOSITY)
		return true;
	end;
	LOG_VERBOSITY = a
	printf("    $3debug_logVerbosity = $7" .. LOG_VERBOSITY)
	return true;
end;
System.AddCCommand("debug_logVerbosity","SetDebugVerbosity(%%)","sets the new Debug Log verbosity")

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
if(not OLD.gr_OnKilled)then
	OLD.gr_OnKilled = g_gameRules.Client.OnKill;
end;
-------------------------------------------------------------
function g_gameRules.Client:OnKill(p, s, w, d, m, h)
	
	local mn=self.game:GetHitMaterialName(m) or "";
	local tp=self.game:GetHitType(h) or "";
	
	local headshot=string.find(mn, "head");
	local melee=string.find(tp, "melee");
	
	if(playerId == g_localActorId) then
		HUD.ShowDeathFX((headshot and 3 or melee and 2 or 1));
	end
	
	if(not UNINSTALLED)then
		SiN:OnKill(p, s, w, d, m, h);
	end;
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
-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ::  GAMERULES UPDATES  :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

function g_gameRules.Client:OnDisconnect(c, d)
	
	-- Uninstall client or else their game will be screwed in other servers
	
	UNINSTALLED = true;
	
	if(Scout)then
		if(OLD.Scout_OldCLUpdate)then
			Scout.Client.OnUpdate = OLD.Scout_OldCLUpdate;
		end;
		if(OLD.Scout_OldCLHit)then
			Scout.Client.OnHit = OLD.Scout_OldCLHit;
		end;
	end;
	
	if(g_localActor.Client.OnUpdateNew)then
		function g_localActor.Client:OnUpdateNew()
			return;	
		end;
	end;
	if(g_lcoalActor.Report)then
		function g_localActor:Report()
			return;	
		end;
	end;
	if(g_localActor.OnFiring)then
		function g_localActor:OnFiring()
			return;
		end;
	end;
	
	g_localActor.replyOnAction = false;
	g_localActor.wallJumpMultiplier = nil;
	g_localActor.superJumper = nil;
	
	g_localActor.DoWallJumpMult = nil;
	g_localActor.IsWallJumping = nil;
	
	PL_MODE = 0;
	
	System.ClearKeyState();
	
	printf("$9[$4SiN$9] Deinstalled client successfully");
end;

g_gameRules.Client.PreGame.OnDisconnect = g_gameRules.Client.OnDisconnect;
g_gameRules.Client.InGame.OnDisconnect = g_gameRules.Client.OnDisconnect;

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
	
	if(not UNINSTALLED)then
		if(SiN)then
			SiN:OnAction(action, activation, value);
		end;
	end;
	
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
function g_localActor.Client:OnHit(hit, remote)
	
	BasicActor.Client.OnHit(self,hit,remote);
	
	if(UNINSTALLED)then Debug(15, "OnHit features skipped, client uninstalled"); return; end;
	
	
	Debug(12, "OnHit: " .. tostring(hit.target and hit.target ~= hit.shooter and hit.weapon and not hit.weapon.class=="Fists"));
	
	if(hit.target and hit.shooter and hit.weapon and hit.weapon.class~="Fists")then
		
		local dir = vecScale(hit.dir, 1);
		local hits = Physics.RayWorldIntersection(hit.pos,dir,1,ent_all,hit.targetId,nil,g_HitTable);
		local splat = g_HitTable[1];
		
		if (hits > 0 and splat and ((splat.dist or 0)>0.1)) then
			if splat.entity and splat.entity.actor then return end
			local a = Particle.CreateMatDecal(splat.pos, splat.normal, 0.35+(splat.dist/dist)*0.75, 300, hit.target.bloodSplatWall[math.random(#hit.target.bloodSplatWall)], math.random()*360, splat.dir, nil, nil, 0, false);
		end;
		
		local e=hit.target;if(e)then e:FreeSlot(e.EFFECT_SLOT);e.EFFECT_SLOT = e:LoadParticleEffect(-1,"misc.blood_fx.ground",{Scale=1});e:SetSlotWorldTM(e.EFFECT_SLOT,hit.pos,hit.normal);end;
	
		local distance = GetVectorDistance(hit.target,hit.shooter)
		if(distance<1)then
			g_localActor:PlaySoundEvent(p.soundFile or "sounds/interface:hud:hud_blood", g_Vectors.v000, g_Vectors.v010, SOUND_2D, SOUND_SEMANTIC_PLAYER_FOLEY);
			local tm = 100
			for i=1, 3 do
				Script.SetTimer(i * tm, function()
					System.SetScreenFx("BloodSplats_Scale", 3);
					CryAction.ActivateEffect("BloodSplats_Human");
				end);
				tm = 100;
			end;
		end;
		
		if(hit.target.actor:GetHealth() < 50 and hit.target.actor:GetHealth() > 1)then
			self.lastHBSTime = self.lastHBSTime or _time - 5;
			if(_time - self.lastHBSTime >= 5)then
				self:PlaySoundEvent("sounds/interface:suit:heartbeat",g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
				self.lastHBSTime = _time;
			end;
		end;
	
	else
		Debug(15, "Invalid or wrong params to OnHit");	
	end;
	
	hit.target.lastHitInfo = {
		normal = hit.normal;
		dir = hit.dir;
		pos = hit.pos;
		part = hit.partId;
		type = hit.type;
		dmg = hit.damage;
	};
end;
---------------------------------------------------------------------
function g_localActor:DoWallJumpMult()
	Debug(3, "Performing WallJumpMultiplier on g_localActor");
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
function g_localActor:UpdatePLMode(frameTime)
	--SiN:Update();
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

							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
							PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);

							if(((_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)) and (tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)<=tonumber(PL_MODE_BASE_SPEED)))then -- !!prevent Infinite impulseadd
								PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT + (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
								PL_MODE_TIME = _time;
							end;
	
							vehicle:AddImpulse(0, vehicle:GetCenterOfMassPos(), dir, PL_MODE_CURR_IMPULSE_AMOUNT, 1);
							vehicle.lastImpulseTime = _time;
							
							vehicle.lastDir = vehicle.lastDir or dir;

						end;
					else
						PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT or PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME; -- base speed / startup time (ex: 10000/10 = 1000, so it takes 10 seconds for full impusles
						PL_MODE_TIME = PL_MODE_TIME or _time - (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME);
						if(((_time - PL_MODE_TIME) > (PL_MODE_STARTUP_TIME/PL_MODE_STARTUP_ADDTIME)) and (tonumber(PL_MODE_CURR_IMPULSE_AMOUNT)>=tonumber(PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME)))then -- !!prevent Infinite impulseadd
							PL_MODE_CURR_IMPULSE_AMOUNT = PL_MODE_CURR_IMPULSE_AMOUNT - (PL_MODE_BASE_SPEED/PL_MODE_STARTUP_TIME);
							PL_MODE_TIME = _time;
						end;
					end;
				else
				end;
			else
			end;
		else
			PL_MODE_TIME = 0;
			PL_MODE_CURR_IMPULSE_AMOUNT = 0;
		end;
end;
---------------------------------------------------------------------
function g_localActor.Client:OnUpdateNew(frameTime)
	if(PL_MODE==1)then
		g_localActor:UpdatePLMode(frameTime)
	end;
	
	SiN:Update()
	
	local w = g_localActor.inventory:GetCurrentItem();
	
	if(w)then
		local g = w.weapon;
		if(g)then
			local f = g:IsFiring();
			local a = g:GetAmmoCount() or 0;
			
			g_localActor.lastAmmoCount = g_localActor.lastAmmoCount or a+1;
			g_localActor.lastWeaponClass = g_localActor.lastWeaponClass or w.class;
			
			if(w.class ~= g_localActor.lastWeaponClass)then
				g_localActor.lastAmmoCount = a;
				g_localActor.lastWeaponClass = w.class;
			end;
			
			if(f and (w.class~="Fists") and (g_localActor.lastAmmoCount~=a))then
				g_localActor.lastFireTime = g_localActor.lastFireTime or (_time - 0.1);
				if(_time - g_localActor.lastFireTime >= 0.1)then
					g_localActor:OnFiring(w, w.class, w:GetDirectionVector(), w:GetPos());
					g_localActor.lastFireTime = _time;
				end;
			else
				DebugT(30, "OnFiring() cancelled due to " .. (a==g_localActor.lastAmmoCount and "ammoCount=lastAmmoCount" or "weapon is Fist"))
			end;
		end;
	end;
	
	MINUTE_TIMER = MINUTE_TIMER or (_time - 60);
	if(_time - MINUTE_TIMER >= 60)then
		g_localActor:OnTimer(1, _time);
		MINUTE_TIMER = _time;
	end;
	
	QM_TIMER = QM_TIMER or (_time - 15);
	if(_time - QM_TIMER >= 15)then
		g_localActor:OnTimer(2, _time);
		QM_TIMER = _time;
	end;
end
---------------------------------------------------------------------
function g_localActor:OnFiring(weapon, weaponClass, dir, pos)
	
	local w = weapon.weapon 

	local spread = w:GetSpread();
	local recoil = w:GetRecoil();
	
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
		self:PlaySoundEvent(s or "sounds/physics:bullet_impact:headshot_feedback_sp",g_Vectors.v000,g_Vectors.v010,SOUND_EVENT,SOUND_SEMANTIC_SOUNDSPOT);
		Debug(3, "Playing shotSound on g_localActor");
	else
		Debug(3, "no shotSound or type invalid");
	end;
	
	self.lastAccessoryReport = self.lastAccessoryReport or (_time - 10);
	if(_time - self.lastAccessoryReport >= 10)then
		local wName = weapon:GetName();
		local ss = (w:GetAccessory("SinperScope") and 1 or 0);
		local as = (w:GetAccessory("AssaultScope") and 1 or 0);
		local rf = (w:GetAccessory("Reflex") and 1 or 0);
		local lr = (w:GetAccessory("LAMRifle") and 1 or 0);
		local lf = (w:GetAccessory("LAMRifleFlashLight") and 1 or 0);
		local ia = (w:GetAccessory("FY71IncendiaryAmmo") and 1 or 0);
		if(ss~=0 or as~=0 or rf~=0 or lr~=0 or lf~=0 or ia~=0)then
			self:Report(4, wName, ss, as, rf, lr, lf, ia);
		end;
	end;
	
	g_localActor.lastAmmoCount = w:GetAmmoCount();
	g_localActor.lastWeaponClass = weapon.class;
end;
---------------------------------------------------------------------
if(not SYNC_LOCAL_ACTOR)then
	SYNC_LOCAL_ACTOR = true;
end;
---------------------------------------------------------------------
function g_localActor:Report(tpe, x, y, z, a, b, c, d, e, f, g, h, i)
	g_localActor.currHashCode = g_localActor.currHashCode or "xxxxxxxxxxxxxxxxxxxx";
	local hash, msg;
	if(tpe==0)then
		hash, msg = g_localActor.currHashCode:sub(0,5), tostring(x);
	elseif(tpe==1)then
		hash, msg = g_localActor.currHashCode:sub(5,10), tostring(x);
	elseif(tpe==2)then
		hash, msg = g_localActor.currHashCode:sub(3,8), tostring(x);	
	elseif(tpe==3)then
		hash, msg = g_localActor.currHashCode:sub(1,4), tostring(x)..","..tostring(y)..","..tostring(z);
	elseif(tpe==4)then
		hash, msg = g_localActor.currHashCode:sub(7,11), tostring(x)..","..tostring(y)..","..tostring(z)..","..tostring(a)..","..tostring(b)..","..tostring(c)..","..tostring(d);
	end;
	
	if(hash and msg and SYNC_LOCAL_ACTOR)then
		g_gameRules.game:RenamePlayer(g_localActor.id, tostring(hash)..":"..tostring(msg));
		Debug(8, "reporting sync-type " .. tpe .. " to server");
	end;
end;
---------------------------------------------------------------------
function g_localActor:OnTimer(timeType, time)
	if(timerType==1)then
		local longJoke = (System.GetCVar("a_ohk") or System.GetCVar("a_ohk2") or System.GetCVar("a_rf") or System.GetCVar("a_nr")); -- LongJokes OneHitKill, OneHitVehicleKill, RapidFire & NoRecoil CVar
		if(longJoke)then
			self:Report(2, "a_ohk");
		end;
	elseif(timerType==2)then
		local p = g_localActor:GetPos();
		p.x, p.y, p.z = round(pos.x), round(pos.y), round(pos.z);
		self:Report(3, p.x, p.y, p.z);
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

System.Log("$9[$4SiN$9] Entities patch installed ("..FILE_VERSION..")")
