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

function round(x)
     return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function GNV(vec3)
	return {x=vec3.x*-1,y=vec3.y*-1,z=vec3.z*-1};
end;

SIN_AI_UPDATE_DELAY = 50;
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

	CopyVector(self.lastHit.dir,hit.dir);
	CopyVector(self.lastHit.pos,hit.pos);
	self.lastHit.partId = hit.partId;
	self:GetVelocity(self.lastHit.velocity);
	self:AddImpulse(hit.partId,hit.pos,hit.dir,hit.damage *  self:GetDamageImpulseMultiplier(hit),2);
	if (damage > 0) then	  
		local maxHealth = self.actor:GetMaxHealth();
		local oldRatio = health/maxHealth;
		local newRatio = __max(0, (health-damage)/maxHealth);
		if (newRatio ~= 0) then	    
			for i,stage in ipairs(self.Vulnerability.DamageEffects) do  	    
				if (oldRatio >= stage.health and newRatio < stage.health) then
					self:SetAttachmentEffect(0, stage.attachment, stage.effect, g_Vectors.v000, g_Vectors.v010, 1, 0);  	    
				end
			end  	    	  
		end
	end
	if (not self.painSoundTriggered) then
		self:SetTimer(PAIN_TIMER,0.15 * 1000);
		self.painSoundTriggered = true;
	end
	return true;
end;


function TryGetDir(entity)
	entity.lastPos = entity.lastPos or entity:GetPos();
	return GetDirectionVector(entity:GetPos(), entity.lastPos, true)
end;

if not OldPatchedSP then OldPatchedSP = SinglePlayer.Client.OnUpdate end

SinglePlayer.Client.OnUpdate = function(self, dt)

	OldPatchedSP(self, dt)

	if not (g_gameRules.class == "InstantAction" or g_gameRules.class == "PowerStruggle") then

		return;

	end
	
	if(LAST_UPDATE)then LAST_UPDATE = tonumber(LAST_UPDATE); end;
	LAST_UPDATE = LAST_UPDATE or _time - SIN_AI_UPDATE_DELAY;
	
	if(_time - LAST_UPDATE >= SIN_AI_UPDATEDELAY)then
		if(UPDATE_AI_ENTITIES)then
		LAST_UPDATE = _time;
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
			--if(v.AI and v.AI.lastHitTarget)then
			--	if(v.lastHitTime and (_time - v.lastHitTime < 25))then
			--		local aimPos = System.GetEntity(v.AI.lastHitTarget);
			--		if(aimPos and aimPos.actor and aimPos.actor:GetHealth()>0)then

						v:SetDirectionVector(TryGetDir(v)); -- mike cause strange directions if SIN_AI_UPDATE_DELAY isn't low enough.

						--if(v.hit_dir)then v:SetDirectionVector(GNV(v.hit_dir)) end; -- didnt work too :s
						--v:SetDirectionVector(GNV(GetDirectionVector(v:GetPos(), aimPos:GetPos(), true))); -- does weird bugs after some time :s
						updated=updated+1;
			--		else
			--			if(SIN_LOG_VERBOSITY and SIN_LOG_VERBOSITY>2)then
			--				printf("$9[$4SiN$9] AISystem: AimTarget not found for " .. v:GetName())
			--			end;
			--		end;
			--	end;
			--end;
			v.lastPos = v:GetPos();
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
		else
			-- dont print error like in old function -> else OVERFLOW :D
		end;
	end;
end


        
        
        

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
		printf("$9[$4SiN$9] AISystem: update delay is " ..SIN_AI_UPDATE_DELAY );
		return true;
	end;
	SIN_AI_UPDATE_DELAY = tonumber(number);
	if(SIN_AI_UPDATE_DELAY<1)then
		SIN_AI_UPDATE_DELAY=1;
	end;
	printf("$9[$4SiN$9] AISystem: new update delay is " ..SIN_AI_UPDATE_DELAY );
	return true;
end;
function ToggleAIUpdate()
	if not UPDATE_AI_ENTITIES then
			UPDATE_AI_ENTITIES = true;
			--FixAIDirectionVectors()
			printf("$9[$4SiN$9] AISystem: enabeling AISystem");
	else
		UPDATE_AI_ENTITIES = false;
		printf("$9[$4SiN$9] AISystem: disabeling AISystem");
	end;
end;
System.AddCCommand("sin_aiLogVerbosity", "SetAILogVerbosity(%%)", "Sets the new SiN-AISystem logging verbosity");
System.AddCCommand("sin_aiUpdateDelay", "SetAIUpdateRate(%%)", "Sets the new SiN-AISystem updating Delay");
System.AddCCommand("sin_aiUpdateSystem", "ToggleAIUpdate()", "if true, AI Entities will be updated and relocated to their correct position");

System.AddCCommand("sin_update", "DownloadLatest()", "re-downloads the SiN-AIFiles");

function DownloadLatest() -- function from diznq from sfwcl client
	local url = "https://raw.githubusercontent.com/FinchMaster101/SiN-SSM-CSC/master/Main.lua";
	local function ExecCode(code)
		if loadstring ~= nil then
			return loadstring(code)()
		elseif load ~= nil then
			return load(code)()
		else
			return false, "cannot find code loader"
		end
	end
	local function EvalCode(code)
		local ok, res = pcall(ExecCode, code)
		if not ok then
			System.LogAlways("$4 [execute] Code execution failed: " .. tostring(res))
		end
	end
	local protocol, host, script = url:match("(https?)://([a-zA-Z0-9_.]+)/(.*)")
	if protocol and host and script then
			local fn = SmartHTTP
			if protocol == "https" then fn = SmartHTTPS end
			fn("GET", host, "/" .. script, function(stuff, err)
			if not err then
				EvalCode(stuff)
			else
				System.LogAlways("$4[http] Failed to fetch " .. protocol .. "://" .. host .. "/" .. script .. ", error: " .. tostring(err))
			end
		end)
	else
		System.LogAlways("$4[http] Invalid URL given: " .. tostring(url))
	end
end;
PerformanceControl = {
	enabled = true;
	limits = {
		{ 20, 500 };
		{ 30, 300 };
		{ 50, 200 };
		{ 80, 100 };
		{ 120, 50 };
		{ 150, 10 };
		{ 200, 1 };
	};
	Update = function(self)
		if(not self.enabled)then return; end;
		self.current = 1/(System.GetFrameTime() or 0.0)
		local newRate, lower = SIN_AI_UPDATEDELAY, 0;
		for i,limit in pairs(self.limits) do
			if(self.current<limit[1])then
				newRate=limit[2];
				lower=limit[1]
			end;
		end;
		if(newRate~=SIN_AI_UPDATEDELAY)then
			SIN_AI_UPDATEDELAY = newRate;
			if(SIN_LOG_VERBOSITY > 2)then
				printf("$9[$4SiN$9] AI: PerformanceControl set update delay to " .. SIN_AI_UPDATEDELAY);
			end;
		end;
	end;
	Toggle = function(self)
		if(not self.enabled)then
			self.enabled=true;
		else
			self.enabled=false;
		end;
		return self.enabled;
	end;
	SetMode = function(self)
		printf("$9[$4SiN$9] AI: PerformanceControl has been " .. (self:Toggle() and "enabled" or "disabled"))
	end;
};

function SetPerformanceMode()
	return PerformanceControl:SetMode()
end;

System.AddCCommand("sin_performanceControl", "SetPerformanceMode()", "toggles the automatic performance control");
          
printf("$9[$4SiN$9] AISystem: Installation finished!");
