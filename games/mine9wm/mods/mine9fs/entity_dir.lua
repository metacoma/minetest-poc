local lfs = require "lfs"
dofile(minetest.get_modpath("mine9fs") .. "/platform.lua")

local level_platform_counter = { 
} 

local drawed_paths = {}


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
  local texture = nil
  minetest.log("set path to " .. path)
  self.path = path
  self.object:set_nametag_attributes({
    {a = 255, r = 255, g = 0, b = 0},
    text = string.gsub(self:get_path(), "(.*/)(.*)", "%2")
  }) 

  if (path == "/kubernetes") then
    texture = "kubernetes.png"
  end

  if (calculate_path_level(path) == 2) then
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

  if (texture ~= nil) then
    self.object:set_properties({
      textures = { texture, texture, texture, texture, texture, texture},
      base_texture = texture
    })
  end
end

function Mine9Dir:get_path() 
  return self.path
end


-- cd directory
function Mine9Dir:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    local path = self:get_path()

    if (puncher and puncher:get_wielded_item():get_name() == "mine9fs:configure") then
      getUserChannel(puncher:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e '" .. path2kubectl(path) .. "'")
      return 
    end
    if (puncher and puncher:get_wielded_item():get_name() == "mine9fs:run") then
      getUserChannel(puncher:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e '" .. path2exec(path) .. "'")
      return 
    end

    local files = get_file_list(path)
    local object_pos = self.object:get_pos()

    if (drawed_paths[path] ~= nil) then 
      player:move_to(random_pos_on_platform(drawed_paths[path], {x = 5, y = 1, z = 5 }, 1))
      return
    end

    local new_platform_pos = calculate_new_platform_pos(path)
    local platform9 = Platform9New(
      new_platform_pos,
      table.getn(files) 
    )
    drawed_paths[path] = new_platform_pos
    platform9:draw()
    for _, file in pairs(files) do  
      local abs_path = ((path == "/") and "" or path) .. "/" ..  file["name"]
      local file_pos = platform9:allocateRandomPos() 
      local entity_type = (file["t"] == "directory") and "mine9fs:dir" or "mine9fs:file"
      local entity = minetest.add_entity(file_pos, entity_type)
      entity:get_luaentity():set_path(abs_path) 
    end
    minetest.chat_send_player(puncher:get_player_name(), dump(files))
    puncher:move_to(random_pos_on_platform(new_platform_pos, {x = 5, y = 1, z = 5 } , 3))
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

function split(s, sep)
    local fields = {}

    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)

    return fields
end

function path2exec(path) 
  local node_name = string.gsub(path, "(.*/)(.*)", "%2")
  local path_nodes = split(path, "/")
  local namespace = path_nodes[2]
  return "kubectl -n " .. namespace .. " exec -ti " .. node_name .. " -- /bin/sh"
end

function path2kubectl(path)
  local path_level = ({string.gsub(path, "/", "")})[2]
  local node_name = string.gsub(path, "(.*/)(.*)", "%2")
  local path_nodes = split(path, "/")
  if (path_level == 2) then
    return "kubectl edit ns " .. node_name
  end
  if (path_level == 4) then
    local namespace = path_nodes[2]
    local resource_type = path_nodes[3]
    return "kubectl -n " .. namespace .. " edit " .. resource_type .. "/" .. node_name
  end
end

