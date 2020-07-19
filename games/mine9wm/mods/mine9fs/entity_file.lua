Mine9File = {
    initial_properties = {
        hp_max = 10000000,
        drawtype = "front",
        physical = true,
        visual = "cube",
        textures = { "mine9fs_file.png",  "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png", "mine9fs_file.png"}, 
        visual_size = {x = 1, y = 1},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
    },
    message = "hi"
}

function Mine9File:on_punch(puncher, time_from_last_punch, tool_capabilities, direction)
    self.object:set_hp(100000)
    minetest.chat_send_player(puncher:get_player_name(), "punch")
    return false
end


