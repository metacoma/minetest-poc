local root_dir = "/"
local lfs = require "lfs"

local start_pos = {
  x = 20,
  y = 25,
  z = 20,
} 

local platform_pos_shift = {
  x = 10, 
  y = 10,
  z = 10
} 

local draw_types = {
  x = 1,
  y = 1,
  z = 1
} 

local is_drawed = false

minetest.register_on_generated(function(minp, maxp, seed)
  if (minp.x <= start_pos.x and start_pos.x <= maxp.x and minp.y <= start_pos.y and start_pos.y <= maxp.y and minp.z <= start_pos.z and start_pos.z <= maxp.z) then
    local start_node = minetest.add_entity(start_pos, "filemanager:dir")  
    start_node:get_luaentity():set_meta({
      name = "/",
      type = "directory"
    })
    start_node:get_luaentity():set_path(root_dir)
  end
end)

minetest.register_on_joinplayer(function(player)
  local player_inventory = player:get_inventory()
  player_inventory:add_item("main", "filemanager:cd")
end)


FileManagerDir = {
    initial_properties = {
        drawtype = "front",
        physical = true,
        visual = "cube",
        textures = { "mine9fs_node.png",  "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png", "mine9fs_node.png"}, 
        visual_size = {x = 1, y = 1},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
        groups = { immortal = 1 },
        automatic_rotate = 3,
        static_save = false
    },
    platform_pos = nil,
    parent = nil,
    path_nodes = {},
    path = nil,
    draw_type = "z",
    platform_area = {} 
} 


FileManagerDir.set_path = function(self, new_path) 
  self.path = new_path
  local basename = string.gsub(self:get_path(), "(.*/)(.*)", "%2")
  local display_path = (basename ~= nil and basename ~= "") and basename or "/"
  self:set_display_path(display_path) 
  if (not self:is_dir()) then
    self.object:set_properties({
        automatic_rotate = 0,
    })
  end
end

FileManagerDir.get_path = function(self) 
  return self.path
end

FileManagerDir.set_display_path = function(self, new_display_path) 
  self.display_path = new_display_path
  self.object:set_nametag_attributes({
    colorspec = self:get_path_color(),
    text = self.display_path
  }) 
end

FileManagerDir.get_display_path = function(self)
  return self.display_path
end

FileManagerDir.set_path_color = function(self, new_color) 
  self.path_color = new_color
end

FileManagerDir.get_path_color = function(self)
  return (self.path_color == nil) and "black" or self.path_color
end


FileManagerDir.z_draw = function(self, attributes) 
  local observer_look_dir = attributes.observer:get_look_dir() 
  if (self:get_parent() == nil) then
  self:set_platform_pos(vector.floor(
    vector.add(attributes.observer:get_pos(),
      { 
        x = observer_look_dir.x * platform_pos_shift.x,
        y = observer_look_dir.y * platform_pos_shift.y,
        z = observer_look_dir.z * platform_pos_shift.z
      } 
      )
    )
  )
  else
    self:set_platform_pos(self:get_parent():get_platform_pos())
  end
  local parent_path = self:get_path()

  -- ".."
  local n = 1
  local entity_pos = self:calc_pos_on_platform(n)
  local entity = minetest.add_entity(entity_pos, "filemanager:dir")
  entity:get_luaentity():set_meta(
    { 
      name = get_parent_dir(self:get_path()),
      type = "directory"
    } 
  )
  entity:get_luaentity():set_path(get_parent_dir(parent_path))
  entity:get_luaentity():set_display_path("..") 
  texture = self:path2texture("..")
  if (texture ~= nil) then
      entity:set_properties({
        textures = { texture, texture, texture, texture, texture, texture},
        base_texture = texture
  })
  end
  entity:get_luaentity():set_parent(self)
  self.path_nodes[n] = entity
  -- 

  for n, file in ipairs(attributes.file_list) do
    entity_pos = self:calc_pos_on_platform(n + 1)
    entity = minetest.add_entity(entity_pos, "filemanager:dir")
    -- XXX refact
    local abs_path = ((parent_path == "/" or parent_path == "//") and "" or parent_path) .. "/" ..  file["name"]
    self.path_nodes[n + 1] = entity
    entity:get_luaentity():set_meta(file) 
    entity:get_luaentity():set_path(abs_path) 
    entity:get_luaentity():set_parent(self)
  
    texture = self:path2texture(entity:get_luaentity():get_path())

    if (not entity:get_luaentity():is_dir()) then
      texture = "mine9fs_file.png"
    end

    if (texture ~= nil) then
      entity:set_properties({
        textures = { texture, texture, texture, texture, texture, texture},
        base_texture = texture
      })
    end

    
  end
end

FileManagerDir.set_parent = function(self, new_parent)
  self.parent = new_parent
end

FileManagerDir.get_parent = function(self)
  return self.parent
end

FileManagerDir.set_meta = function(self, new_meta) 
  self.meta = new_meta
end

FileManagerDir.is_dir = function(self) 
  return self.meta.type == "directory"
end

FileManagerDir.get_file_name = function(self)
  return self.meta.name
end


FileManagerDir.set_platform_pos = function(self, new_platform_pos) 
--  local need_draw = (self:get_parent() == nil) and true or false
  self.platform_pos = new_platform_pos

  --
  if (self:get_parent() ~= nil) then
    minetest.bulk_set_node(self:get_parent():get_platform_area(), { name = "air" })
  end

  local platform_size = self:get_platform_size()
  local area = draw_area(self.platform_pos, { x = platform_size, y = platform_size, z = 1 })     
  self:set_platform_area(area) 
  minetest.bulk_set_node(self:get_platform_area(), { name = "platform:node" })
end

FileManagerDir.set_platform_area = function(self, new_platform_area)
  self.platform_area = new_platform_area
end

FileManagerDir.get_platform_area = function(self)
  return self.platform_area
end

FileManagerDir.get_platform_pos = function(self)
  return self.platform_pos
end

FileManagerDir.calc_pos_on_platform = function(self, element_n) 
  local platform_size = self:get_platform_size() 
  local platform_pos = self:get_platform_pos() 

  local max_elements_in_row = math.floor(platform_size / 3)
  
  if (self:get_draw_type() == "z") then
    return {
      x = platform_pos.x + platform_size - ( 2 * math.fmod(element_n, max_elements_in_row)) - 3, -- - math.floor(element_n / max_elements_in_row - 0.5),
      y = platform_pos.y + platform_size - ( 2 * math.ceil(element_n / max_elements_in_row)) , -- - math.floor(math.fmod(element_n, max_elements_in_row)),
      z = platform_pos.z + 1
    } 
  end 

  if (self:get_draw_type() == "x") then
  end 

  if (self:get_draw_type() == "y") then
  end 
end

FileManagerDir.get_platform_size = function(self)
  return self.platform_size
end
FileManagerDir.set_platform_size = function(self, new_size)
  if (new_size == nil) then
    error("platform size is nil")
  end
  self.platform_size = new_size
end

--[[
FileManagerDir.get_random_pos_on_platform = function(self, shift)
  local draw_type = self:get_draw_type()  
  local platform_area = self:get_platform_area()
  local random_element_n = math.random(1, table.getn(platform_area))  
  local random_pos = platform_area[random_element_n]

  if (draw_type == "x") then
  end
  if (draw_type == "z") then
  end
  if (draw_type == "y") then
  end

  
  return random_pos
  
end
--]]



FileManagerDir.y_draw = function(self, files) 
  minetest.log("y_draw")
end

FileManagerDir.set_draw_type = function(self, new_draw_type) 
  if (draw_types[new_draw_type] == nil) then  
    error("Unknown draw_type " .. new_draw_type)
  end
  draw_type = new_draw_type
end

FileManagerDir.get_draw_type = function(self) 
  return self.draw_type
end


FileManagerDir.draw = function(self, attributes) 
  if (self:get_draw_type() == "z") then
    return self:z_draw(attributes)
  end
  if (self:get_draw_type() == "y") then
    return self:y_draw(attributes)
  end 
end

FileManagerDir.clear_nodes = function(self)
  for pos, node in ipairs(self.path_nodes) do
    node.remove(node)
  end
end

FileManagerDir.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)

  if (not self:is_dir()) then
    minetest.chat_send_player(puncher:get_player_name(), "file " .. self:get_path())
    return
  end

  if (puncher ~= nil) then
    minetest.chat_send_player(puncher:get_player_name(), "cd " .. self:get_path())
  end

  self:clear_nodes() 

  
  local path = self:get_path() 
  local file_list = self:get_file_list()

  --self:set_platform_size(table.getn(file_list))
  self:set_platform_size(math.ceil(math.sqrt(table.getn(file_list) * 8)) + 1)
  self:draw({
    file_list = file_list,
    observer = puncher
  })

end


minetest.register_entity("filemanager:dir", FileManagerDir)
minetest.register_tool("filemanager:cd", {
  range = 200.0,
  inventory_image = "filemanager_cd.png"
})


FileManagerDir.get_file_list = function(self) 
  local file_list = {}
  local path = self:get_path()
--[[
  table.insert(file_list, {
    name = self:get_path(),
    type = "directory"
  })
--]]
  for file in lfs.dir(path) do
    if file ~= "." and file ~= ".." then
      local attr = lfs.attributes (path .. '/' .. file)
      if (attr ~= nil) then
        table.insert(file_list, {
          name = file,
          type = attr.mode
        })
      end
    end
  end
  return file_list
end

function draw_area(pos, size) 
  local p = {}  
  for x = pos.x, pos.x + size.x - 1 do
    for y = pos.y, pos.y + size.y - 1 do
      for z = pos.z, pos.z + size.z - 1 do
        table.insert(p, ({
        x = x,
        y = y,
        z = z,
      })) 
      end 
    end 
  end 
  return p
end


FileManagerDir.path2texture = function(self, path) 
  local texture = nil




  if (path == "/kubernetes") then
    texture = "kubernetes.png"
  end

  if (calculate_path_level(path) == 2 and ({string.gsub(path, "/kubernetes/.*", "")})[2] == 1) then
    texture = "kubernetes_ns.png"
  end

  if (({string.gsub(path, "/pod[$/]?", "")})[2] == 1) then
    texture = "kubernetes_pod.png"
  end
  if (({string.gsub(path, "/serviceaccounts[$/]?", "")})[2] == 1) then
    texture = "kubernetes_sa.png"
  end
  if (({string.gsub(path, "/svc[$/]?", "")})[2] == 1) then
    texture = "kubernetes_svc.png"
  end

  if (({string.gsub(path, "/secrets[$/]?", "")})[2] == 1) then
    texture = "kubernetes_secrets.png"
  end

  if (({string.gsub(path, "/secrets[$/]?", "")})[2] == 1) then
    texture = "kubernetes_sc.png"
  end

  if (({string.gsub(path, "/pvc[$/]?", "")})[2] == 1) then
    texture = "kubernetes_pvc.png"
  end

  if (({string.gsub(path, "/deployments[$/]?", "")})[2] == 1) then
    texture = "kubernetes_deploy.png"
  end

  if (({string.gsub(path, "/daemonsets[$/]?", "")})[2] == 1) then
    texture = "kubernetes_ds.png"
  end

  if (({string.gsub(path, "/nodes[$/]?", "")})[2] == 1) then
    texture = "kubernetes_nodes.png"
  end

  if (({string.gsub(path, "/configmaps[$/]?", "")})[2] == 1) then
    texture = "kubernetes_cm.png"
  end

  if (path == "/ob1" or path == "/ob2" or path == "/ob0") then
    texture = "ssh.png"
  end

  
  if (path == "..") then
    minetest.log("ok " .. path .. " and ..")
    return "two_dots.png"
  end
  minetest.log("path == " .. path .. " self:get_path() = " .. self:get_path())

  return texture
end

function get_parent_dir(path)
  local path_table = split(path, "/")
  table.remove(path_table, #path_table)
  return "/" .. table.concat(path_table, "/")
end
