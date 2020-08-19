minetest.register_tool("mine9p:write", {
  description = "9p write",
  inventory_image = "write.png"
})

minetest.register_tool("mine9p:read", {
  description = "9p read",
  inventory_image = "read.png"
})

minetest.register_tool("mine9p:execute", {
  description = "9p execute",
  inventory_image = "execute.png"
}) 


minetest.register_on_joinplayer(function(player)
  local player_inventory = player:get_inventory()
  player_inventory:add_item("main", "mine9p:write" .. ' 1')
  player_inventory:add_item("main", "mine9p:read" .. ' 1')
  player_inventory:add_item("main", "mine9p:execute" .. ' 1')
end)
