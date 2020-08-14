Nine9Server = {
  initial_properties = {
      drawtype = "front",
      physical = true,
      visual = "cube",
      textures = { "mine9p_server.png",  "mine9p_server.png", "mine9p_server.png", "mine9p_server.png", "mine9p_server.png", "mine9p_server.png"}, 
      visual_size = {x = 1, y = 1},
      spritediv = {x = 1, y = 1},
      initial_sprite_basepos = {x = 0, y = 0},
      groups = { immortal = 1 },
      automatic_rotate = 3
  }
} 

minetest.register_entity("mine9p:Nine9Server", Nine9Server)
