local lfs = require "lfs"

Mine9Dir = {
    initial_properties = {
        hp_max = 10000000,
        drawtype = "front",
        physical = true,
        visual = "cube",
        textures = { "mine9fs_node.png",  "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png"}, 
        visual_size = {x = 1, y = 1},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
    },
    path = nil
}

function Mine9Dir:get_staticdata() 
  return minetest.write_json({ 
    path = self.path
  }) 
end

function Mine9Dir:set_path(path) 
  minetest.log("set path to " .. path)
  self.path = path
  self.object:set_nametag_attributes({
    {a = 255, r = 255, g = 0, b = 0},
    text = self:get_path()
  }) 
end

function Mine9Dir:get_path() 
  return self.path
end


-- cd directory
function Mine9Dir:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    self.object:set_hp(100000)
    local files = get_file_list(self:get_path())
    minetest.chat_send_player(puncher:get_player_name(), dump(files))
    return false
end

function get_file_list(path) 
  local file_list = {}
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      local attr = lfs.attributes (path .. '/' .. file)
      if (attr ~= nil) then
        table.insert(file_list, {
          name = file,
          t = attr.mode
        })
      end
    end
  end
  return file_list
end
