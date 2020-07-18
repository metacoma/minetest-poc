local lfs = require"lfs"

local drawed_paths = { } 

local level_platform_counter = { 
} 

local platform_pos = {
  x = 0,
  y = 7,
  z = 0 
} 

local platform_size = {
  x = 10,
  y = 1, 
  z = 10
}

local shift = { 
  x = 0,
  y = 7,
  z = 0
} 

local root_node = "/tmp/json"

function calculate_new_platform_pos(path) 
  local path_level = calculate_path_level(path) 
  local current_platform_counter = level_platform_counter[path_level] 

  if (current_platform_counter == nil) then
    current_platform_counter = 1
  end

  level_platform_counter[path_level] = current_platform_counter + 1

  return {
      x = platform_pos.x + (current_platform_counter * platform_size.x) + 1,
      y = path_level * 7 + 7,
      z = platform_pos.z + (current_platform_counter * platform_size.z) + 1
  } 
end

minetest.register_node("mine9fs:node", {
  tiles = { "mine9fs_node.png" },
  on_punch = function(pos, node, player, pointed_thing) 

    local path = root_node

    local node_meta = minetest.get_meta(pos):to_table() 
    minetest.log(dump(node_meta))
    if (node_meta.fields.file ~= nil and node_meta.fields.file ~= nil) then
      path = node_meta.fields.file
      if (node_meta.fields.t ~= "directory") then
        return 
      end
    end 

    if (drawed_paths[path] ~= nil) then
      player:move_to(random_pos_on_platform(drawed_paths[path], platform_size, 1))
      return 
    end
  
    local current_platform_pos = calculate_new_platform_pos(path)

    draw_platform(path, current_platform_pos)
    
    player:move_to(random_pos_on_platform(current_platform_pos, platform_size, 1))
    minetest.chat_send_player(player:get_player_name(), "cd " .. path)



  end,
}) 

minetest.register_node("mine9fs:file", {
  tiles = { "mine9fs_file.png" },
}) 

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

function attrdir (path)
    for file in lfs.dir(path) do
        if file ~= "." and file ~= ".." then
            local f = path..'/'..file
            print ("\t "..f)
            local attr = lfs.attributes (f)
            assert (type(attr) == "table")
            if attr.mode == "directory" then
                attrdir (f)
            else
                for name, value in pairs(attr) do
                    print (name, value)
                end
            end
        end
    end
end

function random_pos_on_platform(platform, platform_size, height)
    return {x = (platform.x + 1) + (math.random(1, platform_size.x) - 2), y = platform.y + height, z = (platform.z + 1) + ( math.random(1,platform_size.z) - 2) }
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



function draw_platform(path, start_pos) 

  drawed_paths[path] = start_pos

  local area = draw_area(start_pos, platform_size) 

  minetest.bulk_set_node(area, { name = "platform:node" })

  local files = get_file_list(path)
  for _, file in pairs(files) do
    local new_node_pos = random_pos_on_platform(start_pos, platform_size, 1)
    local node_name = "mine9fs:file"

    if (file["t"] == "directory") then
      node_name = "mine9fs:node"
    end

    minetest.add_node(new_node_pos, { name = node_name } ) 

    minetest.get_meta(new_node_pos):from_table({
      fields = {
        file = ((path == "/") and "" or path) .. "/" ..  file["name"],
        t = file["t"]
      } 
    })
  end

end


function calculate_path_level(path) 
  return table.getn((string.split(path, "/")))
end

signs_lib.register_sign("basic_signs:sign_wall_glass", {
  description = "Glass Sign",
  yard_mesh = "signs_lib_standard_sign_yard_two_sticks.obj",
  tiles = {
    { name = "basic_signs_sign_wall_glass.png", backface_culling = true},
    "basic_signs_sign_wall_glass_edges.png",
    "basic_signs_pole_mount_glass.png",
    nil,
    nil,
    "default_steel_block.png" -- the sticks on back of the yard sign model
  },
  inventory_image = "basic_signs_sign_wall_glass_inv.png",
  default_color = "c",
  locked = true,
  entity_info = "standard",
  sounds = default.node_sound_glass_defaults(),
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
  allow_hanging = true,
  allow_widefont = true,
  allow_onpole = true,
  allow_onpole_horizontal = true,
  allow_yard = true,
  use_texture_alpha = true,
})
-- 
-- 
