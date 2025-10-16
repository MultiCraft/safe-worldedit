local S = minetest.get_translator("worldedit_commands")

--`count` is the number of nodes that would possibly be modified
--`callback` is a callback to run when the user confirms
local max_nodes = tonumber(minetest.settings:get("worldedit.max_region_nodes")) or 20000
max_nodes = math.min(max_nodes, 100000)
local max_size = tonumber(minetest.settings:get("worldedit.max_area_size")) or 128
max_size = math.min(max_size, 1024)
local hard_max_nodes = tonumber(minetest.settings:get("worldedit.hard_max_region_nodes")) or 1000000
hard_max_nodes = math.min(hard_max_nodes, max_size ^ 3)
local abs = math.abs
local safe_region_callback = {}

-- Like vector.equals but doesn't error if the positions are nil
local function pos_eq(pos1, pos2)
	-- If either position is nil then only return true if they're both nil
	if pos1 == nil or pos2 == nil then
		return pos1 == nil and pos2 == nil
	end

	return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

local function safe_region(name, count, callback, strict)
	if count < max_nodes then
		return callback()
	end

	-- Prevent the operation if strict is set (if the safe_area check wasn't used)
	if strict or count > hard_max_nodes then
		worldedit.player_notify(name, S("This operation would affect up to @1 nodes;"
			.. " you can only update @2 nodes at a time", count, strict and max_nodes or hard_max_nodes))
		return
	end

	--save callback to call later
	local pos1, pos2 = worldedit.pos1[name], worldedit.pos2[name]
	safe_region_callback[name] = function()
		-- Replace the current positions with the ones from when the command
		-- was initially executed.
		local old_pos1, old_pos2 = worldedit.pos1[name], worldedit.pos2[name]
		worldedit.pos1[name], worldedit.pos2[name] = table.copy(pos1), table.copy(pos2)

		callback()

		-- If the positions haven't been changed then restore the previous ones
		if pos_eq(worldedit.pos1[name], pos1) and pos_eq(worldedit.pos2[name], pos2) then
			worldedit.pos1[name], worldedit.pos2[name] = old_pos1, old_pos2
		end
	end

	worldedit.player_notify(name, S("WARNING: this operation could affect up to @1 nodes; type @2 to continue or @3 to cancel",
		count, minetest.colorize("#00ffff", "//y"), minetest.colorize("#00ffff", "//n")))
end

local function reset_pending(name)
	safe_region_callback[name] = nil
end

minetest.register_on_leaveplayer(function(player)
	reset_pending(player:get_player_name())
end)

minetest.register_chatcommand("/y", {
	params = "",
	description = S("Confirm a pending operation"),
	privs = {worldedit=true},
	func = function(name)
		local callback = safe_region_callback[name]
		if not callback then
			worldedit.player_notify(name, S("no operation pending"))
			return
		end

		reset_pending(name)
		callback(name)
	end,
})

minetest.register_chatcommand("/n", {
	params = "",
	description = S("Abort a pending operation"),
	privs = {worldedit=true},
	func = function(name)
		if not safe_region_callback[name] then
			worldedit.player_notify(name, S("no operation pending"))
			return
		end

		reset_pending(name)
	end,
})

local function safe_area(name, pos1, pos2)
	if not minetest.is_valid_pos(pos1) or not minetest.is_valid_pos(pos2) then
		return false
	end

	if abs(pos2.x - pos1.x) + 1 > max_size or abs(pos2.x - pos1.x) + 1 > max_size or
			abs(pos2.z - pos1.z) + 1 > max_size then
		worldedit.player_notify(name, S("Your selected area is too big, you can only select areas up to @1 × @2 × @3",
			max_size, max_size, max_size))
		return false
	end
	return true
end

return safe_region, reset_pending, safe_area, max_size
