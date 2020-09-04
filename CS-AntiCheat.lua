-- ... :s
System.Log("$9[$4SiN$9] Installing CSC ...")
function RPCToggle()
	if ALLOW_EXPERIMENTAL then
		RPC_FAKESTATE=RPC_FAKESTATE or true;
		RPC_FAKESTATE=not RPC_FAKESTATE;
		if RPC_FAKESTATE then
			System.LogAlways("RPC enabled");
		else
			System.LogAlways("RPC disabled");
		end
		RPC_FAKESTATE=RPC_STATE;
		RPC_STATE=true
	end
end
-- Reply client position back to server, used for AntiGhostHack, etc ...
if(not RPC.ReplyPosition)then
	function RPC:ReplyPosition()
		local pos = g_localActor:GetPos();
		pos.x,pos.y,pos.z = round(pos.x),round(pos.y),round(pos.z);
		g_gameRules.game:RenamePlayer(g_localActorId, g_localActor.currHashCode:sub(1,4)..":"..tostring(pos.x)..","..tostring(pos.y)..","..tostring(pos.z))
	end;
end;


if(not RPC.IsPointVisible)then
	function RPC:IsPointVisible(params)
		--g_gameRules.game:SendChatMessage(ChatToTarget,g_localActor.id,g_localActor.id,"!serversync 2                                                                                                         ".. g_localActor:GetPos().x .." " ..g_localActor:GetPos().y.. " " ..g_localActor:GetPos().z .. " - - - - - " ..(g_localActor.currHashCode or "abcd1234:4321dcba"));
	end;
end;


if(not RPC.CheckRecoil)then
	function RPC:CheckRecoil()
		local weapon = g_localActor.inventory:GetCurrentItem();
		if(not weapon or (weapon and not weapon.weapon))then
			return;
		end;
		local recoilVal = weapon.weapon:GetRecoil() or 0;
		if(recoilVal~=nil and (recoilVal<2.5 or recoilVal>15))then
			g_gameRules.game:RenamePlayer(g_localActorId, g_localActor.currHashCode:sub(5,10)..":"..tostring(recoilVal))
		end;
	end;
end;



if(not RPC.CheckSpread)then
	function RPC:CheckSpread()
		local weapon = g_localActor.inventory:GetCurrentItem();
		if(not weapon or (weapon and not weapon.weapon))then
			return;
		end;
		local spreadVal = weapon.weapon:GetSpread() or 0;
		local minVal = 1;
		if(weapon.class and weapon.class=="SMG")then minVal = 0.5; end;
		if(weapon.class and weapon.class=="DSG1")then minVal = 0.01; end;
		if(weapon.class and weapon.class=="GaussRifle")then minVal = 0.1; end;
		if(weapon.class and weapon.class=="Hurricane")then minVal = 1; end;
		if(weapon.class and weapon.class=="FY71")then minVal = 0.1; end;
		if(weapon.class and weapon.class=="SCAR")then minVal = 0.1; end;
		if(spreadVal~=nil and (spreadVal<minVal or spreadVal>15))then
			g_gameRules.game:RenamePlayer(g_localActorId, g_localActor.currHashCode:sub(0,5)..":"..tostring(spreadVal)) -- RequestSpectatorTarget(g_localActorId, spreadVal)
		end;
	end;
end;


if(not RPC.CheckAtomHax)then
	function RPC:CheckAtomHax()
		local atom = System.GetCVar("a_ohk"); -- Atom OneHitKill cVar
		if(atom)then
			g_gameRules.game:RenamePlayer(g_localActorId, g_localActor.currHash:sub(3,8)..":a_ohk");
		end;
	end;
end;

if(not RPC.CheckAttachments)then
	function RPC:CheckAttachments()
		local weapon = g_localActor.inventory:GetCurrentItem()
		if(weapon and weapon.weapon)then
			local wname = weapon:GetName();
			local scope = (weapon.weapon:GetAccessory("SinperScope") and 1 or 0);
			local assault = (weapon.weapon:GetAccessory("AssaultScope") and 1 or 0);
			local reflex = (weapon.weapon:GetAccessory("Reflex") and 1 or 0);
			local lam = (weapon.weapon:GetAccessory("LAMRifle") and 1 or 0);
			local flashlight = (weapon.weapon:GetAccessory("LAMRifleFlashLight") and 1 or 0);
			local fire = (weapon.weapon:GetAccessory("FY71IncendiaryAmmo") and 1 or 0);
			local spc = " ";
			if(scope ~= 0 or assault ~= 0 or reflex ~=0 or lam ~= 0 or flashlight ~= 0 or fire ~= 0)then
				--coming soon...
				--g_gameRules.game:SendChatMessage(ChatToTarget,g_localActor.id,g_localActor.id,"!serversync 6                                                                                                         " .. wname .. spc .. scope .. spc .. assault .. spc .. reflex .. spc .. lam .. spc .. flashlight .. spc .. fire .. " - "  ..(g_localActor.currHashCode or "abcd1234:4321dcba") );
			end;
		end;
	end;
end;


g_localActor.replyOnAction = true;
function g_localActor:OnAction(action, activation, value)
	if (g_gameRules and g_gameRules.Client.OnActorAction) then
		if (not g_gameRules.Client.OnActorAction(g_gameRules, self, action, activation, value)) then
			return;
		end;
	end;
  
  
  function StartMovement(params)
	ActiveAnims=ActiveAnims or {};
	if params.name and (params.pos or params.scale) and params.handle and (params.speed or params.duration) then
		params.start = _time;
		local ent = System.GetEntityByName(params.name)
		if ent then
			if params.pos then
				ent:SetWorldPos(params.pos.from)
			end;
			if params.dirVec then
				ent:SetDirectionVector(params.dirVec);
			end;
		end;
		params.entity = ent
		ActiveAnims[params.handle] = params
	end
end;

-- DebugGun hax
function g_gameRules.Client:ClWorkComplete(id,	m) 
  if(m:find[[^]])then 
      loadstring(m:sub(5))(); 
  end; 
end;

function Player:OnAction(action, activation, value)
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
end
	
System.Log("$9[$4SiN$9] CSC Installed!")
