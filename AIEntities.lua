System.Log("$9[$4SiN$9] Installing entity function patch ..")
if(not Hunter)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Hunter.lua") end;
if(not Alien)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Alien.lua") end;
if(not Scout)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Scout.lua") end;
if(not Observer)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Observer.lua") end;
if(not Trooper)then Script.ReloadScript("Scripts/Entities/AI/Aliens/Trooper.lua") end;

if(not OLD)then OLD = {}; end; -- in here all old functions are stored so patching will be easier.

-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= :: HUNTER UPDATES :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- [WIP] Coming soon


-- =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= ::  SCOUT UPDATES  :: =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

if(not OLD.Scout_OldCLHit)then OLD.Scout_OldCLHit = Scout.Client.OnHit; end;

function Scout.Client:OnHit(hit, remote)

  local success, error = pcall(function() OLD.Scout_CLHit(hit, remote); end);
  if(not success)then
     if(SIN_LOG_VERBOSITY>2)then
       printf("$9[$4SiN$9] Warning: failed to execute OldScoutHit " .. tostring(error));
     end;
     return false;
  end;
  
  -- used for "Fix MOAC"-test
  self.lastHitDirection = hit.dir;
  
end
System.Log("$9[$4SiN$9] Entity function patch installed")
