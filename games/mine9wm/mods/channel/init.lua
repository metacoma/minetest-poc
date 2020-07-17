local UserChannels = {}
UserChannels.__index = UserChannels

function UserChannels.new() 
  local self = setmetatable({}, UserChannels)
  self.channels = {} 
  return self
end

function UserChannels.add(self, player_name)  
  self.channels[player_name] = minetest.mod_channel_join(player_name)
end

function UserChannels.get(self, player_name) 
  return self.channels[player_name]
end

local Channels = UserChannels.new() 


minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name() 
    Channels:add(player_name) 
    minetest.chat_send_player(player_name, "CONNECTED")
end)

function getUserChannel(player_name) 
  return Channels:get(player_name) 
end


