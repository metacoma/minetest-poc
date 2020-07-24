Mine9File = {
    initial_properties = {
        drawtype = "front",
        physical = true,
        visual = "cube",
        textures = { "mine9fs_file.png",  "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png"}, 
        visual_size = {x = 1, y = 1},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
        groups = { immortal = 1 }
    },
    path = nil
}

function Mine9File:set_path(path) 
  minetest.log("set path to " .. path)
  self.path = path
  self.object:set_nametag_attributes({
    {a = 255, r = 255, g = 0, b = 0},
    text = self:get_path()
  }) 
end

function Mine9File:get_path() 
  return self.path
end

function Mine9File:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    return false
end


