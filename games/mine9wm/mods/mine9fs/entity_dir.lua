local lfs = require "lfs"
dofile(minetest.get_modpath("mine9fs") .. "/platform.lua")

local level_platform_counter = { 
} 


Mine9Dir = {
    initial_properties = {
        drawtype = "front",
        physical = true,
        visual = "cube",
        textures = { "mine9fs_node.png",  "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png"}, 
        visual_size = {x = 1, y = 1},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
        groups = { immortal = 1 }
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
    local files = get_file_list(self:get_path())
    local object_pos = self.object:get_pos()
    local platform9 = Platform9New({
        x = object_pos.x, 
        y = object_pos.y + 7,
        z = object_pos.z,
      },
      table.getn(files) 
    )
    platform9:draw()
    for _, file in pairs(files) do  
      local abs_path = ((self:get_path() == "/") and "" or self:get_path()) .. "/" ..  file["name"]
      local file_pos = platform9:allocateRandomPos() 
      local entity_type = (file["t"] == "directory") and "mine9fs:dir" or "mine9fs:file"
      local entity = minetest.add_entity(file_pos, entity_type)
      entity:get_luaentity():set_path(abs_path) 
    end
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

function calculate_path_level(path) 
  return table.getn((string.split(path, "/")))
end

