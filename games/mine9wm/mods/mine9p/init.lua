dofile(minetest.get_modpath("mine9p") .. "/mount.lua")
dofile(minetest.get_modpath("mine9p") .. "/readdir.lua")
dofile(minetest.get_modpath("mine9p") .. "/client.lua")
dofile(minetest.get_modpath("mine9p") .. "/server.lua")
dofile(minetest.get_modpath("mine9p") .. "/packet.lua")


minetest.register_entity("mine9p:Nine9MountEntity", Nine9MountEntity) 
