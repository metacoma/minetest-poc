local node_dhcp = "node_dhcp.png"
local wifi_tile = "node_wifi.png"

start_pos = {
  x = 0,
  y = 0,
  z = 0
}

minetest.register_on_generated(function(minp, maxp, seed)
  if (minp.x <= start_pos.x and start_pos.x <= maxp.x and minp.y <= start_pos.y and start_pos.y <= maxp.y and minp.z <= start_pos.z and start_pos.z <= maxp.z) then
      minetest.add_node({ x = 10, y = 1, z = 10 }, { name = "node:wifi"} )
      minetest.add_node({ x = 14, y = 1, z = 14 }, { name = "node:dhcp"} )
      minetest.add_node({ x = 18, y = 1, z = 2 }, { name = "datasource:node"} )
      minetest.add_node({ x = 13, y = 1, z = 10 }, { name = "mine9fs:kubernetes"} )
      local root_dir = minetest.add_entity(
        { 
          x = 15,
          y = 1,
          z = 16
        },
        "mine9fs:dir"
      ) 

      local root_dir = minetest.add_entity(
        { 
          x = 10,
          y = 10,
          z = 15 
        },
        "mine9p:mount"
      ) 

      local root_dir = minetest.add_entity(
        { 
          x = -10,
          y = 10,
          z = -10, 
        },
        "mine9p:mount"
      ) 
    
  end
end)


minetest.register_node("node:dhcp", {
  tiles = { node_dhcp },
  paramtype = "light",
  diggable = false,
  inventory_image = minetest.inventorycube(node_dhcp),
  on_punch = function(pos, node, player, pointed_thing) 
    getUserChannel(player:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e 'ssh -t entrypoint tmuxinator start dhcp'")
  end,

})


minetest.register_node("node:wifi", {
  tiles = { wifi_tile .. "^[colorize:#FF0000^[noalpha" },
  --use_texture_alpha = true,
  --drawtype = "allfaces",
  diggable = false,
  inventory_image = minetest.inventorycube(wifi_tile ),
  on_punch = function(pos, node, player, pointed_thing) 
    getUserChannel(player:get_player_name()):send_all("GNOME_TERMINAL_SCREEN='' gnome-terminal -e 'ssh -t entrypoint tmux attach -t vlan'")
  end,
})
