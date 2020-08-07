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
  local texture = nil
  minetest.log("set path to " .. path)
  self.path = path
  self.object:set_nametag_attributes({
    {a = 255, r = 255, g = 0, b = 0},
    text = self:get_path()
  }) 
  if (({string.gsub(path, "/9gridchan/mnt/plumb/send$", "")})[2] == 1) then
    texture = "mine9fs_plumber.png"
  end

  if (({string.gsub(path, "/inferno/chan/plumb.input$", "")})[2] == 1) then
    texture = "mine9fs_plumber.png"
  end

  if (texture ~= nil) then
    self.object:set_properties({
      textures = { texture, texture, texture, texture, texture, texture},
      base_texture = texture
    })
  end

end

function Mine9File:get_path() 
  return self.path
end

function Mine9File:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    local path = self:get_path()

    if (({string.gsub(path, "^/inferno", "")})[2] == 1) then
      getUserChannel(puncher:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e '/home/bebebeko/bin/plumb_inferno.sh " .. path .. "'")
    end

    if (({string.gsub(path, "^/9gridchan", "")})[2] == 1) then
      getUserChannel(puncher:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e '/home/bebebeko/bin/plumb_9front.sh " .. path .. "'")
    end
end
