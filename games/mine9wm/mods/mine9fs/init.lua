local lfs = require"lfs"

dofile(minetest.get_modpath("mine9fs") .. "/entity_file.lua")
dofile(minetest.get_modpath("mine9fs") .. "/entity_dir.lua")

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


    if (file["t"] == "directory") then
      minetest.add_node(new_node_pos, { name = "mine9fs:node" } ) 
      minetest.get_meta(new_node_pos):from_table({
        fields = {
          file = ((path == "/") and "" or path) .. "/" ..  file["name"],
          t = file["t"]
        } 
      })
    end
    if (file["t"] == "file") then
      local entity = minetest.add_entity(new_node_pos, "mine9fs:file")
      entity:set_nametag_attributes({
        {a = 255, r = 255, g = 0, b = 0},
        text = file["name"] 
      }) 
    end

  end

end


function calculate_path_level(path) 
  return table.getn((string.split(path, "/")))
end

minetest.register_node("mine9fs:file", {
  tiles = { "mine9fs_file.png" }
})


minetest.register_entity("mine9fs:file", Mine9File) 
minetest.register_entity("mine9fs:dir", Mine9Dir) 
