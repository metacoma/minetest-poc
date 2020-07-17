local platform_node_tile = "platform_node.png" 

start_pos = { 
  x = 0,
  y = 0, 
  z = 0
}
start_ground_size = { 
  x = 20, 
  y = 1, 
  z = 20 
} 

minetest.register_on_joinplayer(function(player)
    print("register_on_joinplayer")
    player:set_pos(random_pos_on_start_ground(10))

    return player
end)



function random_pos_on_start_ground(height)
    return {x = (start_pos.x + 1) + (math.random(1, start_ground_size.x) - 2), y = start_pos.y + height, z = (start_pos.z + 1) + ( math.random(1,start_ground_size.z) - 2) }
end

minetest.register_on_generated(function(minp, maxp, seed)
  if (minp.x <= start_pos.x and start_pos.x <= maxp.x and minp.y <= start_pos.y and start_pos.y <= maxp.y and minp.z <= start_pos.z and start_pos.z <= maxp.z) then
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
    local data = vm:get_data()
    local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})

    for x = start_pos.x, start_pos.x + start_ground_size.x - 1 do
      for y = start_pos.y, start_pos.y + start_ground_size.y - 1 do
        for z = start_pos.z, start_pos.z + start_ground_size.z - 1 do
          data[area:index(x,y,z)] = minetest.get_content_id("platform:node")
        end
      end
    end
    vm:set_data(data)
    vm:write_to_map()

  end

  for x = 20, 30 do
    minetest.add_node({
      x = x,   
      y = 10,
      z = 10
    }, { name = "platform:node" }) 

  end

  for y = 20, 30 do
    minetest.add_node({
      x = 10,   
      y = y,
      z = 10
    }, { name = "platform:node" }) 

  end
 

end)

minetest.register_node("platform:node", {
  drawtype = "glasslike_framed",
  tiles = { platform_node_tile },
  inventory_image = minetest.inventorycube( platform_node_tile ),
  paramtype = "light",
  sunlight_propagates = true, 
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
})


minetest.register_node("platform:node2", {
  drawtype = "glasslike_framed",
  tiles = { platform_node_tile .. '^[colorize:#FF00FF:096' },
  inventory_image = minetest.inventorycube( platform_node_tile ),
  paramtype = "light",
  sunlight_propagates = true, 
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
})

--npcf:register_npc("platform:jenkins" ,{
--  description = "Jenkins",
--})
