SiN=SiN or{
	-------------------------------
	EventManager={
		Events={
			["Test"] = function(sender)
				SiN:Reply("[EventManager] Event \"test\" called");
			end;
		};
		OnEvent=function(self,sender,event)
			if(sender and event)then
				if(self.Events[tostring(event)])then
					SiN:Execute(self.Events[tostring(event)],sender);
				end;
			end;
		end;
	};
	-------------------------------
	Execute=function(self,code,...)
		local s,e=pcall(code(...));
		if(not s and e)then
			self:Error(g_localActor, tostring(e));
		end;
	end;
	-------------------------------
	Error=function(self,error)
		if(error and fct)then
			g_gameRules.game:SendChatMessage(1,g_localActor.id,g_localActor.id,"[SiN] Lua Error: " ..tostring(error));
		end;
	end;
	-------------------------------
	Reply=function(self,message)
		if(error and fct)then
			g_gameRules.game:SendChatMessage(1,g_localActor.id,g_localActor.id,tostring(message));
		end;
	end;
};
