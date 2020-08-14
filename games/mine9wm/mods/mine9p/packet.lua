Nine9Packet = {
  initial_properties = {
      drawtype = "front",
      physical = false,
      visual = "cube",
      textures = { "mine9p_Rattach.png",  "mine9p_Rattach.png", "mine9p_Rattach.png", "mine9p_Rattach.png", "mine9p_Rattach.png", "mine9p_Rattach.png"}, 
      visual_size = {x = 1, y = 1},
      spritediv = {x = 1, y = 1},
      initial_sprite_basepos = {x = 0, y = 0},
      groups = { immortal = 1 },
      automatic_rotate = 3
  },
  dest_name = nil
} 

function Nine9Packet:set_dest(new_dest) 

  assert(new_dest ~= nil) 

  self.dest_name = new_dest
end

function Nine9Packet:on_step() 
  local current_pos = self.object:get_pos()
  local node_metadata_ref = minetest.get_meta(current_pos):to_table() 

  local meta_fields = node_metadata_ref["fields"] 

  if (meta_fields ~= nil) then
    if (meta_fields["name"] == self.dest_name) then
      self.object:remove()
      packet_count = packet_count - 1
    end
  end

end

minetest.register_entity("mine9p:Nine9Packet", Nine9Packet)


