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
