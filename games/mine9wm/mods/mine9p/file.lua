Nine9File = {
  initial_properties = {
      drawtype = "front",
      physical = true,
      visual = "cube",
      textures = { "mine9p_file.png",  "mine9p_file.png", "mine9p_file.png", "mine9p_file.png", "mine9p_file.png", "mine9p_file.png"}, 
      visual_size = {x = 1, y = 1},
      spritediv = {x = 1, y = 1},
      initial_sprite_basepos = {x = 0, y = 0},
      groups = { immortal = 1 },
  },
} 

Nine9File.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)
  if (puncher) then
    local player_name = puncher:get_player_name() 
  end
end

minetest.register_entity("mine9p:file", Nine9File)
