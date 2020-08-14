local socket = require 'socket'
local np = require '9p'

Nine9MountEntity = {
  initial_properties = {
      drawtype = "front",
      physical = true,
      visual = "cube",
      textures = { "mine9p_9p.png",  "mine9p_styx.png", "mine9p_glenda.png", "mine9p_glenda.png", "mine9p_9p.png", "mine9p_styx.png"}, 
      visual_size = {x = 1, y = 1},
      spritediv = {x = 1, y = 1},
      initial_sprite_basepos = {x = 0, y = 0},
      groups = { immortal = 1 },
      automatic_rotate = 3
  },
  source = nil   
} 


function Nine9MountEntity:set_source(self, new_source) 
  assert(new_source) 
  self.source = new_source
end

function Nine9MountEntity:get_source(self) 
  return self.source
end

guessing = {}

function mount_formspec(name)
    -- TODO: display whether the last guess was higher or lower
    local text = "Entrer source and target"

    local formspec = {
        "formspec_version[3]",
        "size[6,7]",
        "label[0.375,0.5;", minetest.formspec_escape(text), "]",
        "field[0.375,1.50;5.25,0.8;source;Source;]",
        "field[0.375,3;8.25,0.8;target;Target;]",
        "button[1.5,4;2.75,0.8;mount;Mount]"
    }

    -- table.concat is faster than string concatenation - `..`
    return table.concat(formspec, "")
end

Nine9MountEntity.on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction)
  if (puncher) then
    local player_name = puncher:get_player_name() 
    minetest.show_formspec(player_name, "mine9p:mount", mount_formspec())
  end
end

minetest.register_entity("mine9p:mount", Nine9MountEntity)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "mine9p:mount" then
      minetest.log(dump(fields))
      minetest.close_formspec(player:get_player_name(), formname)
      local tcp = socket:tcp()

      local source = string.split(fields.source, "!") 
      minetest.log(dump(source))
      minetest.log("Connect to " .. source[1] .. "!" .. source[2] .. "!" .. source[3])

      local connection, err = tcp:connect(source[2], tonumber(source[3]))
      

      if (err ~= nil) then
        error("Connection error")
      end

      local conn = np.attach(tcp, "bebebeko", "")

      local root_dir = readdir(conn, "./")
      --for n, file in pairs(root_dir) do
      --  minetest.log(dump(file))
      --end

      local player_pos = player:get_pos()

      local platform = Platform9New({
        x = player_pos.x,
        y = player_pos.y + 15, 
        z = player_pos.z,
      }, #root_dir) 
      platform:draw()

      for _, file in pairs(root_dir) do
        local pos = platform:allocateRandomPos() 
        local entity_type = (file.qid.type == 128) and "mine9fs:dir" or "mine9fs:file"
        local entity = minetest.add_entity(pos, entity_type)
        entity:set_nametag_attributes({
          Colorspec = {a = 255, r = 255, g = 13, b = 14},
          text = file.name
        }) 
      end


    end
end)
