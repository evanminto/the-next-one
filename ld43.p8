pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- utils

function merge_arrays(a1, a2)
	local a = {}

	for k,v in a1 do
		a.insert(v)
	end

	for k,v in a2 do
		a.insert(v)
	end

	return a
end









-- data functions

function get_door_pos(wall)
	if wall == 't' then
		return 60, 0
	elseif wall == 'r' then
		return w, 60
	elseif wall == 'b' then
		return 60, h
	elseif wall == 'l' then
		return 0, 60
	end
end

function get_door_sprite(wall, base_s)
	if wall == 't' then return base_s end
	if wall == 'r' then return base_s + 1 end
	if wall == 'b' then return base_s + 2 end
	if wall == 'l' then return base_s + 3 end

	return base_s
end

function create_door(wall, opt)
	local d = {
		sprite = 9
	}

	local room_num = nil

	if not opt then
		opt = {}
	end

	if opt.locked then
		d.locked = true
		d.sprite = 13
	end

	if wall then
		d.wall = wall
	end

	if opt.exit then
		d.exit = true
	end

	if opt.cell then
		d.cell = true
		d.sprite = 25
	end

	if opt.room_num then
		d.room_num = opt.room_num
	end

	if opt.door_num then
		d.door_num = opt.door_num
	end

	local x, y = get_door_pos(wall)

	if x and y then
		d.x = x
		d.y = y
	end

	return d
end

function create_pit(x,y, xtiles,ytiles, opt)
	return {
		x = x,
		y = y,
		xtiles = xtiles,
		ytiles = ytiles,
		sprite = 2,
		c_threshold = 4
	}
end

function create_platform(x,y, opt)
	return {
		x = x,
		y = y,
		sprite = 3,
		falling = false,
		falling_counter = const.platform_fall_duration,
		fell = false,
		c_threshold = -2
	}
end

function create_key(x,y)
	return {
		x = x,
		y = y,
		sprite = 17,
		collected = false,
		item = 'key'
	}
end

function create_lamp(x,y)
	return {
		x = x,
		y = y,
		sprite = 18,
		collected = false,
		item = 'lamp'
	}
end

function get_character_sprite()
	return character_sprites[1 + flr(rnd(7))]
end








-- init
function _init()
	move_to_room(1, 'l')
	text = "You awake in a dungeon. The\ncorpse has a note that says\n\"I may not escape, but if I\nleave something for the next\nprisoner maybe they will.\""
	music(0)
end










-- game logic

-- collide with map boundaries
function cmap(o)
	local c = {}
	local target = 8 - max(o.c_threshold or 0, map_c_threshold or 0)

	if o.x<target then
		c.xmin = true
	end
	if o.x+target>w then
		c.xmax = true
	end
	if o.y<target then
		c.ymin = true
	end
	if o.y+target>h then
		c.ymax = true
	end

	return c
end

-- collide with another object
function cobj(o1,o2)
	local c = {}

	local w1 = 8
	local w2 = 8
	local h1 = 8
	local h2 = 8

	if o1.xtiles then
		w1 = o1.xtiles * 8
	end
	if o2.xtiles then
		w2 = o2.xtiles * 8
	end
	if o1.ytiles then
		h1 = o1.ytiles * 8
	end
	if o2.ytiles then
		h2 = o2.ytiles * 8
	end

	local dx = (o2.x + w2/2) - (o1.x + w1/2)
	local dy = (o2.y + h2/2) - (o1.y + h1/2)

	local xtarget = w1/2 - (o1.c_threshold or 0) + w2/2 - (o2.c_threshold or 0)
	local ytarget = h1/2 - (o1.c_threshold or 0) + h2/2 - (o2.c_threshold or 0)

	if dy < 0 and dy > -ytarget and dx > -xtarget and dx < xtarget then
		c.t = true
	end
	if dx > 0 and dx < xtarget and dy > -ytarget and dy < ytarget then
		c.r = true
	end
	if dy > 0 and dy < ytarget and dx > -xtarget and dx < xtarget then
		c.b = true
	end
	if dx < 0 and dx > -xtarget and dy > -ytarget and dy < ytarget then
		c.l = true
	end

	c.any = c.t or c.r or c.b or c.l

	return c
end

function move()
  player.moving = true
end

function handle_keyboard_movement()
	player.moving = false

	local c = cmap(player)

  if btn(0) and not c.xmin then
		player.x -= player.speed
		player.xmirror = true
    move()
  end
  if btn(1) and not c.xmax then
    player.x += player.speed
		player.xmirror = false
    move()
  end
  if btn(2) and not c.ymin then
    player.y -= player.speed
    move()
  end
  if btn(3) and not c.ymax then
    player.y += player.speed
    move()
  end
end

function move_through_door(door)
	if door.exit then
		mode = 'win'
	end

	if not door or not door.room_num or not door.wall then
		return
	end

	if door.locked and not inventory.key then
		return
	end

	local new_wall = nil

	if door.wall == 't' then new_wall = 'b' end
	if door.wall == 'r' then new_wall = 'l' end
	if door.wall == 'b' then new_wall = 't' end
	if door.wall == 'l' then new_wall = 'r' end

	move_to_room(door.room_num, new_wall)
end

function move_to_room(rnum, wall)
	room_num = rnum

	local r = rooms[rnum]

	if wall then
		if wall == 't' then
			player.x = 60
			player.y = 8
		end

		if wall == 'r' then
			player.x = w - 8
			player.y = 60
		end

		if wall == 'b' then
			player.x = 60
			player.y = h - 8
		end

		if wall == 'l' then
			player.x = 8
			player.y = 60
		end
	end
end

function reset_platforms()
	for _,r in pairs(rooms) do
		if r.platforms then
			for _,p in pairs(r.platforms) do
				p.falling = false
				p.fell = false
				p.falling_counter = const.platform_fall_duration
			end
		end
	end
end

function refresh_player_character()
	player.character = get_character_sprite()
	player.xmirror = false
end

function die()
	death_count += 1

	add(bodies, {
		x = 16 + rnd(w - 32),
		y = 16 + rnd(h - 32)
	})

	reset_platforms()
	refresh_player_character()
	move_to_room(1, 'l')
end

function fall()
	player.falling = true
	player.falling_counter = const.player_fall_duration
end

function get_c_door(doors)
	for _,d in pairs(doors) do
		if cobj(player, d).any then
			return d
		end
	end
end

function get_c_item(items)
	for _,i in pairs(items) do
		if cobj(player, i).any then
			return i
		end
	end
end

function is_c_pit(pits)
	for _,p in pairs(pits) do
		if cobj(player, p).any then
			return true
		end
	end
end

function get_c_platforms(platforms)
	ps = {}

	for _,p in pairs(platforms) do
		if not p.fell then
			if cobj(player, p).any then
				add(ps, p)
			end
		end
	end

	return ps
end

function start_platforms_falling(platforms)
	for _,p in pairs(platforms) do
		p.falling = true
	end
end

function collect_item(item)
	if item then
		item.collected = true
		inventory[item.item] = true
	end
end

function update_platforms(platforms)
	for _,p in pairs(platforms) do
		if p.falling and not p.fell then
			p.falling_counter -= const.platform_fall_rate

			if p.falling_counter <= 0 then
				p.fell = true
				p.falling = false
			end
		end
	end
end

function update_player()
	if player.falling then
		player.falling_counter -= const.player_fall_rate

		if player.falling_counter <= 0 then
			player.falling = false
			die()
		end
	else
		handle_keyboard_movement()
	end
end

function update_play()
	if text ~= '' then
		if btn(4) or btn(5) then
			text = ''
		end
	else
		if not player.falling then
			local r = rooms[room_num]
			local c_door = nil
			local c_pit = false
			local c_item = nil

			if r.doors then
				c_door = get_c_door(r.doors)
			end

			if r.pits then
				c_pit = is_c_pit(r.pits)
			end

			if r.items then
				c_item = get_c_item(r.items)
			end

			if c_pit and r.platforms then
				c_platforms = get_c_platforms(r.platforms)

				if #c_platforms > 0 then
					start_platforms_falling(c_platforms)
					c_pit = false
				end
			end

			if c_pit then
				fall()
			end

			if c_door then
				move_through_door(c_door)
			end

			if c_item then
				collect_item(c_item)
			end

			if r.platforms then
				update_platforms(r.platforms)
			end
		end

		update_player()
	end
end

function _update()
	if mode == 'play' then
		update_play()
	elseif mode == 'win' then

	end

	frame += 1
end










-- drawing

function draw_sprite(obj)
	spr(
		obj.sprite,
		obj.x,
		obj.y,
		1,
		1,
		obj.xmirror
	)
end

function draw_doors(doors)
	if doors then
		for _,d in pairs(doors) do
			draw_sprite({
				x = d.x,
				y = d.y,
				sprite = get_door_sprite(d.wall, d.sprite)
			})
		end
	end
end

function draw_pits(pits)
	if pits then
		for _,p in pairs(pits) do
			rectfill(
				p.x, p.y,
				p.x + p.xtiles*8 - 1, p.y + p.ytiles*8 - 1,
				0
			)
		end
	end
end

function draw_platforms(platforms)
	if platforms then
		for _,p in pairs(platforms) do
			if not p.fell then
				if p.falling and p.falling_counter < const.platform_fall_duration/2 then
					sspr(24,0, 8,8, p.x+1,p.y+1, 6,6)
				elseif p.falling and p.falling_counter < const.platform_fall_duration/4 then
					sspr(24,0, 8,8, p.x+2,p.y+2, 4,4)
				else
					draw_sprite(p)
				end
			end
		end
	end
end

function draw_items(items)
	if items then
		for _,i in pairs(items) do
			if not i.collected then
				draw_sprite(i)
			end
		end
	end
end

function draw_player()
	if player.falling then
		draw_sprite({
			sprite = 33,
			x = player.x,
			y = player.y
		})
		if player.character ~= 2 then
			draw_sprite({
				-- Directly below in sprite sheet
				sprite = player.character + 16,
				x = player.x,
				y = player.y
			})
		end
	else
		local torso_offset = 0

		if player.moving then
			torso_offset = 1 - get_aframe(2, 8)

			draw_sprite({
				sprite = 48 + get_aframe(2, 8),
				x = player.x,
				y = player.y,
				xmirror = player.xmirror
			})
		else
			draw_sprite({
				sprite = 32,
				x = player.x,
				y = player.y,
				xmirror = player.xmirror
			})
		end

		draw_sprite({
			sprite = player.sprite,
			x = player.x,
			y = player.y - torso_offset,
			xmirror = player.xmirror
		})
		draw_sprite({
			sprite = player.character,
			x = player.x,
			y = player.y - torso_offset,
			xmirror = player.xmirror
		})
	end
end

function draw_darkness()
	local r = rooms[room_num]
	local x0 = 8
	local y0 = 8
	local x1 = w-1
	local y1 = h-1

	if not r.light and not inventory.lamp then
		rectfill(
			x0, y0,
			x1, y1,
			0
		)

		return
	end

	local lx = player.x
	local ly = player.y

	if r.light and not inventory.lamp then
		lx = r.light.x
		ly = r.light.y
	end

	local size = 16
	local corner_size = 8

	-- top
	rectfill(
		x0, y0,
		x1, ly - size,
		0
	)

	-- right
	rectfill(
		lx + 8 + size, ly - size,
		x1, ly + 8 + size,
		0
	)

	-- bottom
	rectfill(
		x0, ly + 8 + size,
		x1, y1,
		0
	)

	-- left
	rectfill(
		x0, ly - size,
		lx - 1 - size, ly + 8 + size,
		0
	)

	-- top left
	rectfill(
		lx - size, ly - size,
		lx - size + corner_size, ly - size + corner_size,
		0
	)

	-- top right
	rectfill(
		lx + 8 + size - corner_size, ly - size,
		lx + 8 + size, ly - size + corner_size,
		0
	)

	-- bottom right
	rectfill(
		lx + 8 + size - corner_size, ly + 8 + size - corner_size,
		lx + 8 + size, ly + 8 + size,
		0
	)

	-- bottom left
	rectfill(
		lx - size, ly + 8 + size - corner_size,
		lx - size + corner_size, ly + 8 + size,
		0
	)
end

function get_aframe(num, rate)
	return flr((frame / rate) % num)
end

function draw_room()
	local r = rooms[room_num]

	if not r then
		return
	end

	draw_pits(r.pits)
	draw_platforms(r.platforms)

	if r.dark then
		draw_darkness()
	end

	draw_items(r.items)
end

function draw_room_top()
	local r = rooms[room_num]

	if not r then
		return
	end

	draw_doors(r.doors)

	if not r.dark then
		local aframe = get_aframe(3, 8)

		map(32 + aframe * 16,0, 0,0, 16,16)
	end
end

function draw_inventory()
	if inventory.key or inventory.lamp then
		rectfill(
			w-2.75*8,h+0.125*8,
			w-0.25*8,h+0.75*8,
			0
		)

		rectfill(
			w-2.625*8,h+1*8,
			w-0.375*8,h+0*8,
			0
		)
	end

	if inventory.key then
		sspr(72,24, 8,8, w-1.375*8,h, 8,8)
	end

	if inventory.lamp then
		sspr(80,24, 8,8, w-2.5*8,h, 8,8)
	end
end

function draw_text(text)
	rectfill(
		0,h-32,
		w+8,h+8,
		8
	)
	rectfill(
		0,h-32,
		w+8,h+8-2,
		0
	)

	print(text, 8, h-28, 7)
	print()
end

function draw_play()
	palt(0, false)
	palt(3, true)

	map(0,0, 0,0, 16,16)
	draw_room()
	map(16,0, 0,0, 16,16)
	draw_room_top()

	if room_num == 1 and #bodies > 0 then
		for _,b in pairs(bodies) do
			draw_sprite({
				sprite = 23,
				x = b.x,
				y = b.y
			})
		end
	end

	draw_player()
	draw_inventory()

	if text ~= '' then
		draw_text(text)
	end

	-- local label = flr((frame / 12) % 3)

	-- print(label, 0, 0, 8)
end

function hcenter(s)
  -- screen center minus the
  -- string length times the
  -- pixels in a char's width,
  -- cut in half
  return 64-#s*2
end

function vcenter(s)
  -- screen center minus the
  -- string height in pixels,
  -- cut in half
  return 61
end

function draw_win()
	label = 'you escaped!'
	print(label, hcenter(label), vcenter(label) - 8, 8)

	local plural_str = 'prisoner'
	if death_count ~= 1 then
		plural_str = plural_str .. 's'
	end

	label = death_count .. ' ' .. plural_str .. ' sacrificed'
	print(label, hcenter(label), vcenter(label) + 8, 8)
end

function _draw()
	cls()

	if mode == 'play' then
		draw_play()
	elseif mode == 'win' then
		draw_win()
	end
end












-- data

const = {
	player_fall_duration = 30,
	player_fall_rate = 2,

	platform_fall_duration = 40,
	platform_fall_rate = 2
}

frame = 1

text = ''

character_sprites = {
	2,
	34,
	35,
	36,
	37,
	38,
	39
}

bodies = {
	{
		x = 16,
		y = 16
	}
}

player = {
	x = 12,
	y = 60,
	sprite = 0,
	speed = 2,
	c_threshold = 0,
	falling = false,
	falling_counter = const.player_fall_duration,
	character = get_character_sprite()
}

inventory = {
	key = false,
	lamp = false
}

map_c_threshold = 0

w = 120
h = 120

death_count = 0

mode = 'play'

rooms = {
	-- 1: start
	{
		doors = {
			create_door('t', {
				locked = true,
				room_num = 5
			}),

			create_door('r', {
				room_num = 2
			}),

			create_door('b', {
				room_num = 7
			}),

			create_door('l', {
				cell = true
			})
		}
	},
	-- 2: crumbling bridge puzzle 1
	{
		doors = {
			create_door('l', {
				room_num = 1
			}),

			create_door('r', {
				room_num = 3
			})
		},
		pits = {
			create_pit(40,8, 6,14)
		},
		platforms = {
			create_platform(40,80),
			create_platform(48,80),
			create_platform(56,80),
			create_platform(64,80),
			create_platform(72,80),
			create_platform(80,80)
		},
		items = {}
	},
	-- 3: crumbling bridge puzzle 2
	{
		doors = {
			create_door('l', {
				room_num = 2
			}),

			create_door('r', {
				room_num = 4
			})
		},
		pits = {
			create_pit(40,8, 6,14),
			create_pit(88,8, 6,4),
			create_pit(88,88, 6,4)
		},
		platforms = {
			create_platform(40,40),
			create_platform(48,40),
			create_platform(56,40),
			create_platform(64,40),
			create_platform(64,48),
			create_platform(64,56),
			create_platform(72,56),
			create_platform(80,56)
		},
		items = {}
	},
	-- 4: key
	{
		doors = {
			create_door('l', {
				room_num = 3
			})
		},
		pits = {
			create_pit(8,8, 3,3),
			create_pit(w-3*8,8, 3,3),
			create_pit(w-3*8,h-3*8, 3,3),
			create_pit(8,h-3*8, 3,3)
		},
		platforms = {},
		items = {
			create_key(60, 60)
		}
	},
	-- 5: crumbling bridge puzzle 3
	{
		doors = {
			create_door('b', {
				locked = true,
				room_num = 1
			}),

			create_door('r', {
				room_num = 6
			})
		},
		pits = {
			create_pit(8,8, 14,2),
			create_pit(8,24, 2,12),
			create_pit(48,24, 9,12),
			create_pit(24,48, 3,9)
		},
		platforms = {
			create_platform(56, h-8),
			create_platform(64, h-8),
			create_platform(56, h-2*8),
			create_platform(56, h-3*8),
			create_platform(56, h-4*8),
			create_platform(48, h-4*8),
			create_platform(40, h-4*8),
			create_platform(32, h-4*8),
			create_platform(32, h-5*8),
			create_platform(32, h-6*8),
			create_platform(32, h-7*8),
			create_platform(32, h-8*8),
			create_platform(32, h-9*8),

			create_platform(48, 4*8),
			create_platform(56, 4*8),
			create_platform(64, 4*8),
			create_platform(64, 5*8),
			create_platform(72, 5*8),
			create_platform(80, 5*8),
			create_platform(80, 5*8),
			create_platform(88, 5*8),
			create_platform(88, 4*8),
			create_platform(88, 3*8),
			create_platform(88, 2*8),
			create_platform(96, 2*8),
			create_platform(104, 2*8),
			create_platform(112, 2*8),
			create_platform(112, 3*8),
			create_platform(112, 4*8),
			create_platform(112, 5*8),
			create_platform(112, 6*8),
			create_platform(112, 7*8),
			create_platform(112, 8*8)
			-- create_platform(104, 6*8),
			-- create_platform(112, 6*8)
		},
		items = {}
	},
	-- 6: lamp room
	{
		dark = true,
		doors = {
			create_door('l', {
				room_num = 5
			})
		},
		pits = {
			create_pit(48, 48, 4,4)
		},
		platforms = {
			create_platform(48, 48),
			create_platform(56, 48),
			create_platform(64, 48),
			create_platform(72, 48),
			create_platform(48, 56),
			create_platform(56, 56),
			create_platform(64, 56),
			create_platform(72, 56),
			create_platform(48, 64),
			create_platform(56, 64),
			create_platform(64, 64),
			create_platform(72, 64),
			create_platform(48, 72),
			create_platform(56, 72),
			create_platform(64, 72),
			create_platform(72, 72)
		},
		items = {
			create_lamp(60, 60)
		},
		light = {
			x = 60,
			y = 60
		}
	},
	-- 7: dark pit puzzle
	{
		dark = true,
		doors = {
			create_door('t', {
				room_num = 1
			}),

			create_door('b', {
				room_num = 8
			})
		},
		pits = {
			create_pit(8,8, 6,8),
			create_pit(72,8, 6,4),
			create_pit(104,32, 2,11),
			create_pit(56,56, 4,2),
			create_pit(24,h-32, 10,2),
			create_pit(72,h-16, 4,2)
		},
		platforms = {},
		items = {}
	},
	-- 8: dark crumble
	{
		dark = true,
		doors = {
			create_door('t', {
				room_num = 1
			}),

			create_door('r', {
				room_num = 9,
				locked = true
			})
		},
		pits = {
			create_pit(8,32, 11,12),
			create_pit(w-24,8, 3,3),
			create_pit(w-24,48, 3,1)
		},
		platforms = {
			create_platform(w-24, 8),
			create_platform(w-24+8, 8),
			create_platform(w-24+16, 8),
			create_platform(w-24, 16),
			create_platform(w-24+8, 16),
			create_platform(w-24+16, 16),
			create_platform(w-24, 24),
			create_platform(w-24+8, 24),
			create_platform(w-24+16, 24),

			create_platform(8, 32),
			create_platform(8, 32+8),
			create_platform(8, 32+2*8),
			create_platform(8, 32+3*8),
			create_platform(8, 32+4*8),
			create_platform(8, 32+5*8),
			create_platform(8, 32+6*8),
			create_platform(8, 32+7*8),
			create_platform(2*8, 32+7*8),
			create_platform(3*8, 32+7*8),
			create_platform(4*8, 32+7*8),
			create_platform(5*8, 32+7*8),
			create_platform(6*8, 32+7*8),
			create_platform(7*8, 32+7*8),
			create_platform(8*8, 32+7*8),
			create_platform(9*8, 32+7*8),
			create_platform(10*8, 32+7*8),
			create_platform(11*8, 32+7*8)
		},
		items = {}
	},
	-- 9: red herring dark crumble
	{
		dark = true,
		doors = {
			create_door('t', {
				room_num = 10,
				exit = true
			}),

			create_door('l', {
				room_num = 8,
				locked = true
			})
		},
		pits = {
			create_pit(16,8, w-8,h-8)
		},
		platforms = {
			create_platform(16, 64),
			create_platform(16, 56),
			create_platform(24, 64),
			create_platform(24, 56),
			create_platform(32, 64),
			create_platform(40, 64),
			create_platform(48, 64),
			create_platform(56, 64),
			create_platform(56, 56),
			create_platform(56, 48),
			create_platform(56, 40),

			create_platform(56, 64+1*8),
			create_platform(56, 64+2*8),
			create_platform(56, 64+3*8),
			create_platform(56, 64+4*8),

			create_platform(56+1*8, 64+4*8),
			create_platform(56+2*8, 64+4*8),
			create_platform(56+3*8, 64+4*8),
			create_platform(56+4*8, 64+4*8),
			create_platform(56+5*8, 64+4*8),

			create_platform(96, 64+3*8),
			create_platform(96, 64+2*8),
			create_platform(96, 64+1*8),
			create_platform(96, 64),
			create_platform(96, 64-1*8),
			create_platform(96, 64-2*8),

			create_platform(96, 40),
			create_platform(96, 32),
			create_platform(96, 24),
			create_platform(96, 16),
			create_platform(96, 8),
			create_platform(88, 8),
			create_platform(80, 8),
			create_platform(72, 8),
			create_platform(64, 8),
			create_platform(56, 8),
			create_platform(56, 16),
			create_platform(64, 16)
		},
		items = {}
	}
}

room_num = 1










__gfx__
330000331111111133333333011d1110dddddddd11111d1d11111111d1d111111111111d33000033300000333000000333000003339999333999993339999993
33044443111111113333333311d11111ddd1ddd11111d1dd11111111dd1d1111111111d130000003000000030000000030000000399999939999999399900999
30404043111111113333333311ddd1dd1d1d1d1d11111ddd11111111ddd1111111111d1100000000000000000000000000000000999009999990099999900999
34444443111dd111333333331111ddd1d1d1d1d11111d1dd11111111dd1d11111111d11100000000000000000000000000000000990000999000009999000099
33444433111dd11133333333dd11d1111111111111111d1dd1d1d1d1d1d11111d1dd111100000000000000000000000000000000990000999000009999000099
34666633111111113333333311dddd11111111111111d1dd1d1d1d1ddd1d11111d1d111100000000000000000000000000000000999009999990099999900999
34666433111111113333333311d11d111111111111111dddd1ddd1ddddd11111d1d1111100000000000000033000000330000000999009999999999339999993
3333333311111111333333330d111d10111111111111d1dddddddddddd1d1111dd1d111130000003300000333300003333000003399999933999993333999933
339999993333333333355333333ff33311111111000000000000000033333333d111111133333333333333330000000033000003000000000000000000000000
39999999333333333355553333f4ff33111111110000000000000000366336661d11111133333333333333330000000036666666000000000000000000000000
9990099999933333355555533f4f4ff31111111100000000000000006886060611d1111133333333333333330000000000066600000000000000000000000000
9900000993999999339aa933fff4ffff11111111000000000000000036660666111d111133333333333333330000000066666666000000000000000000000000
9900000999933939339aa933f4fff4ff111111110000000000000000366606061111d1d133333333333333330000000000000000000000000000000000000000
9990099933333333339aa933fffffff3d1d1d1d100000000000000006888666611111d1d33333333333333330000000066666666000000000000000000000000
3999999933333333339889333ff4ff331d1d1d1d0000000000000000868888881111d1dd33333333333333330000000030000000000000000000000000000000
33999999333333333555555333fff333d1d1d1d10000000000000000333333331111dddd33333333333333330000000033666663000000000000000000000000
333333333333333333aaaa3333ffff33300000033000000333888883337777731111d1dd00000000338383333338383333383333000000000000000000000000
33333333333333333aaffff333fffff330ffff030004444338fffff33774444311111d1d00000000333833333338333333833333000000000000000000000000
33333333343003433afcfcf33ff4f4f330f1f1f3044040433ff1f1f3374040431111d1d100000000338888333333883333383833000000000000000000000000
33333333346446433ffffff33ffffff33ffffff3044444433ffffff3344444431111dd1d00000000338898333388883333898333000000000000000000000000
33333333333663333affff3333ffff3333ffff330044440333ffff3333444433111d111100000000333993333339933333399833000000000000000000000000
33333333333553333f3333333f3333333f333333043333033f3333333433333311d1111100000000333443333334433333344333000000000000000000000000
33535333333333333f333f333f333f333f333f33343334333f333f33343334331d11111100000000333443333334433333344333000000000000000000000000
3353533333333333333333333333333333333333333333333333333333333333d111111100000000333333333333333333333333000000000000000000000000
3333333333333333333333333333333333333333333333333333333333333333ddd1111133333333333333330000000000000000000000000000000000000000
3333333333333333333333333333333333333333333333333333333333333333dd1d111133333333333553330000000000000000000000000000000000000000
33333333333333333f3aa3f33f3ff3f33f3003f3343003433f3883f334377343d1d1111139993333355555530000000000000000000000000000000000000000
33333333333333333f3ff3f33f3ff3f33f3ff3f3343443433f3ff3f334344343dd1d111139399993339aa9330000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333331111d11139993993339aa9330000000000000000000000000000000000000000
335333333333533333333333333333333333333333333333333333333333333311111d1133333333339889330000000000000000000000000000000000000000
3353533333535333333333333333333333333333333333333333333333333333111111d133333333355555530000000000000000000000000000000000000000
33335333335333333333333333333333333333333333333333333333333333331111111d33333333333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddddfddddddddffdfdfffdddfddffdfddddfdfdddddddddddddddddddddddddddddddfddddddfddffddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__map__
18060606060606060606060606060608180606060606060606060606060606080202022a02020202020202022a0202020202022b02020202020202022b0202020202022c02020202020202022c020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0501010101010101010101010101010705020202020202020202020202020207020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
2804040404040404040404040404043828040404040404040404040404040438020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101010101010101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101010101010101010102020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020202010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020202020202020202020202020202020202020202020202020202020202010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010202020202020202020202020202020202020202020202020202020202020202010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
__sfx__
001200100c0600c0600c0600c0600c0600c0600c0600c0600f0600f0600f0600f0600f0600f0600f0600f06000000000000000000000000000000000000000000000000000000000000000000000000000000000
0012001018060180601806018060200602006020060200601b0601b0601b0601b0601d0601d0601d0601d06000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
02 00014344

