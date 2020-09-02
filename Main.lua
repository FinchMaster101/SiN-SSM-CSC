printf("$9[$4SiN$9] AISystem: Starting to install ..")
------------------------------------------------------
function GetDirectionVector(a, b, normalize)
  local p1, p2 = (not a.id and a or a:GetPos()),(not b.id and b or b:GetPos());
  p1.x, p1.y, p1.z = (p1.x - p2.x), (p1.y - p2.y), (p1.z - p2.z);
  if(normalize)then
    NormalizeVector(p1)
  end;
  return p1;
end;

SIN_AI_UPDAREDELAY = 50;
UPDATE_AI_ENTITIES=true;

if(not BasicAlien)then Script.ReloadScript("Scripts/Entities/Actor/BasicAlien.lua") end;
function BasicAlien.Client:OnHit(hit, remote)
	local health = self.actor:GetHealth();
	if (health <= 0) then
		return false;
	end
	local t, s = hit.target, hit.shooter;
	if(t and t~=s)then
		t.AI = t.AI or {};
		t.AI.lastHitTarget = s.id;
		t.lastHitTime = _time;
		if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>3)then
			printf("$9[$4SiN$9] AISystem: setting new lastHitTarget for " .. t:GetName())
		end;
	end;
	if(s and s~=t)then
		s.AI = s.AI or {};
		s.AI.lastHitTarget = t.id;
		s.lastHitTime = _time;
		if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>3)then
			printf("$9[$4SiN$9] AISystem: setting new lastHitTarget for " .. s:GetName())
		end;
	end;
	local damageMult = self:GetDamageMultiplier(hit);
	local damage = hit.damage * damageMult;
	if (self.hit) then
		self.hit_dir = hit.dir;
	else
		self.hit = true;
		self.hit_dir = hit.dir;
	end

	CopyVector(alienEnt.lastHit.dir,hit.dir);
	CopyVector(alienEnt.lastHit.pos,hit.pos);
	self.lastHit.partId = hit.partId;
	self:GetVelocity(self.lastHit.velocity);
	self:AddImpulse(hit.partId,hit.pos,hit.dir,hit.damage *  self:GetDamageImpulseMultiplier(hit),2);
	if (damage > 0) then	  
		local maxHealth = self.actor:GetMaxHealth();
		local oldRatio = health/maxHealth;
		local newRatio = __max(0, (health-damage)/maxHealth);
		if (newRatio ~= 0) then	    
			for i,stage in ipairs(alienEnt.Vulnerability.DamageEffects) do  	    
				if (oldRatio >= stage.health and newRatio < stage.health) then
					self:SetAttachmentEffect(0, stage.attachment, stage.effect, g_Vectors.v000, g_Vectors.v010, 1, 0);  	    
				end
			end  	    	  
		end
	end
	if (not alienEnt.painSoundTriggered) then
		self:SetTimer(PAIN_TIMER,0.15 * 1000);
		self.painSoundTriggered = true;
	end
	return true;
end;




function FixAIDirectionVectors()
	local allScouts=System.GetEntitiesByClass("Scout");
	local allGrunts=System.GetEntitiesByClass("Grunt");
	local allAIEntities = {};
	local allAIEntities = {};
	for i,v in ipairs(allScouts or {}) do
		table.insert(allAIEntities, v);
	end;
	for i,v in ipairs(allGrunts or {}) do
		table.insert(allAIEntities, v);
	end;
	local updated=0
	for i,v in ipairs(allAIEntities or {}) do
		if(v.AI and v.AI.lastHitTarget)then
			if(v.lastHitTime and (_time - v.lastHitTime < 25))then
				local aimPos = System.GetEntity(v.AI.lastHitTarget);
				if(aimPos and aimPos.actor and aimPos.actor:GetHealth()>0)then
					v:SetDirectionVector(GetDirectionVector(v:GetPos(), aimPos:GetPos(), true));
					updated=updated+1;
				else
					if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>2)then
						printf("$9[$4SiN$9] AISystem: AimTarget not found for " .. v:GetName())
					end;
				end;
			end;
		end;
	end;
	if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>3)then
		if(#allAIEntities==0)then
			printf("$9[$4SiN$9] AISystem: no entities found to relocate directions ...")
		elseif(#allAIEntities>0 and updated==0)then
			printf("$9[$4SiN$9] AISystem: WARNING: all AI entities are missing lastHitTarget; skipping relocate")
		elseif(updated~=#allAIEntities)then
			printf("$9[$4SiN$9] AISystem: WARNING: " .. (#allAIEntities-updated).." entities are missing lastHitTarget; skipping relocate")
		else
			printf("$9[$4SiN$9] AISystem: relocated " .. updated .. " AIEntities")
		end;
	end;
	Script.SetTimer(tonumber(SIN_AI_UPDAREDELAY or 0),function() if(UPDATE_AI_ENTITIES==true)then FixAIDirectionVectors(); else printf("$9[$4SiN$9] AISystem: WARNING: AIUpdating is disabled, failed to relocate entities") end; end);
end;
        
if(not Player)then Script.ReloadScript("Scripts/Entities/Actor/Player.lua"); end;
function Player.Client:OnHit(hit, remote)
	BasicActor.Client.OnHit(self,hit,remote);
	local t, s = hit.target, hit.shooter;
	if(t and s and t~=s and (s.isAlien or s.class=="Grunt"))then
		s.AI = s.AI or {};
		s.AI.lastHitTarget = t.id;
		s.lastHitTime = _time;
		if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>3)then
			printf("$9[$4SiN$9] AISystem: setting new lastHitTarget for " .. s:GetName())
		end;
	end;
	if(t and s and t~=s and (s.isAlien or s.class=="Grunt"))then
		t.AI = s.AI or {};
		t.AI.lastHitTarget = s.id;
		t.lastHitTime = _time;
		if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>3)then
			printf("$9[$4SiN$9] AISystem: setting new lastHitTarget for " .. t:GetName())
		end;
	end;
end;
        
        
        

UPDATE_AI_ENTITIES=true
SIN_LOG_VERBOSITY=0
FixAIDirectionVectors()
				
function SetAILogVerbosity(number)
	if(not number)then
		printf("    $3sin_aiLogVerbosity = $6"..SIN_LOG_VERBOSITY)
		return true;
	end;
	SIN_LOG_VERBOSITY = tonumber(number);
	if(SIN_LOG_VERBOSITY<0)then
		SIN_LOG_VERBOSITY=0;
		printf("    $3sin_aiLogVerbosity = $6"..SIN_LOG_VERBOSITY)
	end;
end;
function SetAIUpdateRate(number)
	if(not number)then
		printf("$9[$4SiN$9] AISystem: update delay is " ..SIN_AI_UPDAREDELAY );
		return true;
	end;
	SIN_AI_UPDAREDELAY = tonumber(number);
	if(SIN_AI_UPDAREDELAY<1)then
		SIN_AI_UPDAREDELAY=1;
	end;
	printf("$9[$4SiN$9] AISystem: new update delay is " ..SIN_AI_UPDAREDELAY );
	return true;
end;
function ToggleAIUpdate()
	if not UPDATE_AI_ENTITIES then
			UPDATE_AI_ENTITIES = true;
			FixAIDirectionVectors()
			printf("$9[$4SiN$9] AISystem: enabeling AISystem");
	else
		UPDATE_AI_ENTITIES = false;
		printf("$9[$4SiN$9] AISystem: disabeling AISystem");
	end;
end;
System.AddCCommand("sin_aiLogVerbosity", "SetAILogVerbosity(%%)", "Sets the new SiN-AISystem logging verbosity");
System.AddCCommand("sin_aiUpdateDelay", "SetAIUpdateRate(%%)", "Sets the new SiN-AISystem updating Delay");
System.AddCCommand("sin_aiUpdateSystem", "ToggleAIUpdate()", "if true, AI Entities will be updated and relocated to their correct position");
          
printf("$9[$4SiN$9] AISystem: Installation finished!");
