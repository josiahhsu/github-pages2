pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include shared/grid.p8
#include shared/state.p8

function _init()
	cls()
	
	board = nil
	current_board = nil
	px,py,pback=0,0,nil
	dir_map=
	{ //dx,dy,opposite dir
		[⬆️]={0,-1,⬇️},
		[⬇️]={0,1,⬆️},
		[⬅️]={-1,0,➡️},
		[➡️]={1,0,⬅️}
	}
	state = title_state()
end

function _update()
	state.controls()
	state.update()
end

function _draw()
	cls()
	state.draw()
end

// corrupts the game state.
// defaults to corrupting once.
function corrupt(n)
	n = n or 1
	
	for i=1,n do
		poke(abs(rnd(-1)),rnd(-1))
	end
end

// wait n frames
function wait(n)
	for i=0,n do
		flip()
	end
end

function base_state()
	local s = template_state()
	music(-1)
	sfx(4)
	cls()
	wait(16)
	return s
end
-->8
// main menu
function title_state()
	local s=template_state()
	s.time = 0
	s.mirror = false
	s.show_help = false
	
	function s.update()
		s.time+=1
		if s.time % 36 == 0 then
			s.time = 0
			s.mirror=not s.mirror
		end
	end
	
	function draw_help()
		local txt = {
		"corruption is a game where you",
		"race against the degredation",
		"of the game itself!", "",
		"use 🅾️/❎ to roll the die and",
		"advance towards the goal.", "",
		"beware: landing on the ! spaces",
		"will corrupt your game session!",
		}
		
		for i=1, #txt do
			print(txt[i],0,8+8*i, 7)
		end
	end
	
	function draw_title()
		map(0,0)
		local txt = {
		"🅾️ to start",
		"❎ for help"
		}
		for i=1, #txt do
			print(txt[i],42,72+8*i, 7)
		end
		spr(32,64,56,1,1,s.mirror)
	end
	
	function s.draw()
		if s.show_help then
			draw_help()
		else
			draw_title()
		end
	end
	
	s.set_btnp(❎,function()
		s.show_help = not s.show_help
	end)
	
	s.set_btnp(🅾️,function()
		if s.show_help then
			s.show_help = false
		else
			start_game()
			state = board_state()
		end
	end)
	
	music(0)
	return s
end

function start_game()
	current_board=ceil(rnd(3))*16
	local function make_cell(x,y)
		local cell = {}
		local m=mget(x+current_board,y)
		cell.path = fget(m,0)
		cell.corrupt = fget(m,1)
		cell.minigame = fget(m,2)
		cell.finish = fget(m,3)
		cell.start = fget(m,4)
		return cell
	end
	board=create_grid(14,14,true,
	                 make_cell)
	
	px,py,pback=0,0,nil
	local function init_player(x,y)
		if board.get(x,y).start then
			px,py = x,y
		end
	end
	board.do_all(init_player)
end

function draw_spr(s,x,y)
	spr(s,x*8,y*8)
end
-->8
// board
function board_state()
	local s=base_state()
	s.roll_count=0
	s.roll_result=0
	s.is_rolling=false
	
	function s.update()
		if s.roll_count > 0 then
			s.roll_result=roll()
			s.roll_count-=1
			if s.roll_count == 0 then
				s.is_rolling = false
			end
		end
	end
	
	function s.draw()
		map(current_board,0)
		local res = 2*s.roll_result
		spr(34+res,16,96,2,2)
		draw_spr(32,px,py)
	end
	
	local function valid_move(x,y)
		if board.in_bounds_x(x) and
		   board.in_bounds_y(y) then
			return board.get(x,y).path
		end
		return false
	end
	
	local function move_player(dir)
		local dx,dy,back = unpack(dir_map[dir])
		if not s.is_rolling and
		   s.roll_result > 0 and
		   dir != pback and
		  valid_move(px+dx,py+dy) then
			px += dx
			py += dy
			pback=back
			s.roll_result-=1
			local cell = board.get(px,py)
			if cell.finish then
				state = win_state()
			end
			if s.roll_result == 0 then
				if cell.corrupt then
					corrupt(750)
				elseif cell.minigame then
					state = snake_state(10)
				end
			end
		end
	end
	
	s.set_btnp(⬅️,move_player,⬅️)
	s.set_btnp(➡️,move_player,➡️)
	s.set_btnp(⬆️,move_player,⬆️)
	s.set_btnp(⬇️,move_player,⬇️)
	
	local function do_roll()
	if not s.is_rolling and
		   s.roll_result == 0 then
			s.roll_count=20
			s.is_rolling=true
		end
	end
	
	s.set_btnp(🅾️,do_roll)
	s.set_btnp(❎,do_roll)
	
	music(1)
	return s
end

function roll()
	return ceil(rnd(6))
end

// win screen
function win_state()
	local s=base_state()
	
	function s.draw()
		map(0,16)
	end
	
	local function fn()
		state=title_state()
	end
	
	s.set_btn(🅾️,fn)
	s.set_btn(❎,fn)
	
	music(0)
	return s
end
-->8
// mini games
function snake_state(goal)
	local s=base_state()
	s.x,s.y,s.canturn,s.dir,s.back,s.t=
	1,1,true,➡️,⬅️,0
	s.body={}
	
	local function turn(dir)
		local dx,dy,back = unpack(dir_map[dir])
		if s.canturn and
		   dir != s.dir and
		   dir != s.back then
			s.dir = dir
			s.back = back
			s.canturn=false
		end
	end
	
	s.set_btnp(⬅️,turn,⬅️)
	s.set_btnp(➡️,turn,➡️)
	s.set_btnp(⬆️,turn,⬆️)
	s.set_btnp(⬇️,turn,⬇️)
	
	local function body_in_cell(x,y)
		local in_cell = false
		foreach(s.body,function(c)
			if c.x == x and c.y == y then
				in_cell = true
			end
		end)
		return in_cell
	end
	
	local function valid_move(x,y)
		return s.grid.in_bounds_x(x) and
		       s.grid.in_bounds_y(y) and
		       not body_in_cell(x,y)
	end
	
	
	local function spawn_food()
		while true do
			local x,y=ceil(rnd(14)),ceil(rnd(14))
			if not (s.x == x and s.y == y) and
			   not body_in_cell(x,y) then
				s.grid.get(x,y).food = true
				return
			end
		end
	end
	
	local function move_snake()
		local dx,dy,back=unpack(dir_map[s.dir])
		if valid_move(s.x+dx,s.y+dy) then
			local cell = s.grid.get(s.x,s.y)
			add(s.body, cell)
			s.x+=dx
			s.y+=dy
			if cell.food then
				cell.food = false
				if (#s.body == goal) then
					state = board_state()
				end
				spawn_food()
			else
				deli(s.body,1)
			end
			return true
		end
		return false
	end
	
	function s.update()
		s.t += 1
		if s.t % 5 == 0 then
			s.t = 0
			if not move_snake() then
				corrupt(750)
				state = board_state()
			end
			s.canturn = true
		end
	end
	
	function s.draw()
		cls()
		map(16,16)
		
		s.grid.do_all(function(x,y)
			local cell = s.grid.get(x,y)
			if cell.food then
				draw_spr(21,x,y)
			end
		end)
		
		draw_spr(17+s.dir,s.x,s.y)
		foreach(s.body,function(cell)
			draw_spr(16,cell.x,cell.y)
		end)
	end
	
	local function make_cell(x,y)
		local cell = {}
		cell.x = x
		cell.y = y
		cell.food = false
		return cell
	end
	s.grid=create_grid(14,14,true,
	                   make_cell)
	spawn_food()
	music(2)
	return s
end
__gfx__
00000000555555553333333399999999dddddddddddddddddddddddd11111111111111111dddddddddddddd111111111ddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd778877dd777777d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd778877dd7ee777d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd778877dd7eeee7d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd778877dd7eeee7d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd777777dd7ee777d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000566666653bbbbbb398888889d777777dd778877dd777777d1dddddddddddddd11dddddddddddddd1ddddddddddddddd11ddddddddddddddddddddddd
00000000555555553333333399999999dddddddddddddddddddddddd1dddddddddddddd11111111111111111ddddddddddddddd11ddddddd11111111dddddddd
03333330033333300333333003333330033333300000330000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb30088300000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33b3bbbb33bbbb3b33b3bb3b33bbbbbb30888888000000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb38888878800000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb38888878800000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33b3bbbb33bbbb3b33bbbbbb33b3bb3b38888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
3bbbbbb33bbbbbb33bbbbbb33bbbbbb33bbbbbb30888888000000000000000000000000000000000000000000000000000000000000000000000000000000000
03333330033333300333333003333330033333300088880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00cccc00000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
0ccc77c0000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
0cccc7c0000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
0cccccc0000000005777777777777775577777777777777557755777777777755775577777777775577557777775577557755777777557755775577777755775
00cccc00000000005777777777777775577777777777777557755777777777755775577777777775577557777775577557755777777557755775577777755775
00cccc00000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
0cccccc0000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
cccccccc000000005777777777777775577777755777777557777777777777755777777557777775577777777777777557777775577777755775577777755775
00000000000000005777777777777775577777755777777557777777777777755777777557777775577777777777777557777775577777755775577777755775
00000000000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
00000000000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
00000000000000005777777777777775577777777777777557777777777557755777777777755775577557777775577557755777777557755775577777755775
00000000000000005777777777777775577777777777777557777777777557755777777777755775577557777775577557755777777557755775577777755775
00000000000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
00000000000000005777777777777775577777777777777557777777777777755777777777777775577777777777777557777777777777755777777777777775
00000000000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700007777000077770007777700077777700777777000777700070000700777777007777770070000700700000007000070070000700077770000777700
07000070070000700700007007000070070000000700000007000000070000700000700000007000070007000700000007700770077000700700007007000070
07000070070000700700000007000070070000000700000007000000070000700000700000007000070070000700000007077070070700700700007007000070
07777770077777000700000007000070077770000777700007000000077777700000700000007000077700000700000007000070070070700700007007777700
07000070070000700700000007000070070000000700000007000770070000700000700000007000070070000700000007000070070007700700007007000000
07000070070000700700007007000070070000000700000007000070070000700000700007007000070007000700000007000070070000700700007007000000
07000070007777000077770007777700077777700700000000777700070000700777777007777000070000700777777007000070070000700077770007000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077777000777777007777770070000700700007007000070070000700700007007777770000770000000000000000000000000000000000000000000
07000070070000700700000000007000070000700700007007000070007007000070070000000070000770000000000000000000000000000000000000000000
07000070070000700700000000007000070000700700007007000070000770000007700000000700000770000000000000000000000000000000000000000000
07000070077777000777777000007000070000700700007007000070000770000000700000007000000770000000000000000000000000000000000000000000
07007070070070000000007000007000070000700700007007077070000770000000700000070000000770000000000000000000000000000000000000000000
07000700070007000000007000007000070000700070070007700770007007000000700000700000000000000000000000000000000000000000000000000000
00777070070000700777777000007000007777000007700007000070070000700000700007777770000770000000000000000000000000000000000000000000
__label__
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000055555555
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
55555555000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000055555555
55555555000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000555555550000000055555555
56666665000000005666666500777700007777000777770007777700070000700077770007777770077777700077770007000070566666650000000056666665
56666665000000005666666507000070070000700700007007000070070000700700007000007000000070000700007007700070566666650000000056666665
56666665000000005666666507000000070000700700007007000070070000700700007000007000000070000700007007070070566666650000000056666665
56666665000000005666666507000000070000700777770007777700070000700777770000007000000070000700007007007070566666650000000056666665
56666665000000005666666507000000070000700700700007007000070000700700000000007000000070000700007007000770566666650000000056666665
56666665000000005666666507000070070000700700070007000700070000700700000000007000000070000700007007000070566666650000000056666665
55555555000000005555555500777700007777000700007007000070007777000700000000007000077777700077770007000070555555550000000055555555
55555555000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000055555555
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
56666665000000005666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666650000000056666665
55555555000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
555555550000000000000000000000000000000000000000000000000000000000cccc0000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000ccc77c000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000cccc7c000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000cccccc000000000000000000000000000000000000000000000000056666665
566666650000000000000000000000000000000000000000000000000000000000cccc0000000000000000000000000000000000000000000000000056666665
566666650000000000000000000000000000000000000000000000000000000000cccc0000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000cccccc000000000000000000000000000000000000000000000000056666665
5555555500000000000000000000000000000000000000000000000000000000cccccccc00000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000005555555555555555555555555555555555555555555555550000000000000000000000000000000055555555
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
56666665000000000000000000000000000000005666666556666665566666655666666556666665566666650000000000000000000000000000000056666665
55555555000000000000000000000000000000005555555555555555555555555555555555555555555555550000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000007777700000077700770000007707770777077707770000000000000000000000000000000000055555555
56666665000000000000000000000000000000000077000770000007007070000070000700707070700700000000000000000000000000000000000056666665
56666665000000000000000000000000000000000077070770000007007070000077700700777077000700000000000000000000000000000000000056666665
56666665000000000000000000000000000000000077000770000007007070000000700700707070700700000000000000000000000000000000000056666665
56666665000000000000000000000000000000000007777700000007007700000077000700707070700700000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000007777700000077700770777000007070777070007770000000000000000000000000000000000055555555
56666665000000000000000000000000000000000077070770000070007070707000007070700070007070000000000000000000000000000000000056666665
56666665000000000000000000000000000000000077707770000077007070770000007770770070007770000000000000000000000000000000000056666665
56666665000000000000000000000000000000000077070770000070007070707000007070700070007000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000007777700000070007700707000007070777077707000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056666665
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
56666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665566666655666666556666665
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555

__gff__
0000091101030500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101020000000000000000000000000001010000000000000000000000000000010100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101040004040400000000000000000001010004040405050604050404040500010100050504000000000000000002000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010101010101010101010101000101050505000600000004040504000001010004000000000000000000000500010100040004040604050400050504000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010001424e5151544f53484e4d01000101000000000404050405000004000001010005000406050404040504040400010100040000000000000400050000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100010101010101010101010101000101000000000000000000000006000001010004000400000000000000000000010100040605040404000400040406000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000004000001010006000404050404050406040400010100000000000005000600000004000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000404040006040400000005000001010004000000000000000000000400010100000404060405000405000005000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000010101010101000000000101000500050505000504000005000001010004000000040404040406040500010100000400000000000005040404000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000600000000000004000004000001010004040300050000000000000000010100000404050406000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000404040604000006000004000001010000000000040604050404040400010100000000000004040405060404000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101070b0b08000500000400000500000101070b0b08000000000000000005000101070b0b08000000000000000004000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000000000000000001010d0f0f0c0005000005040406000001010d0f0f0c0002000000000000050001010d0f0f0c000404060404030005000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000000000000000000000000001010d0f0f0c0004000000000000000001010d0f0f0c0004040505050406040001010d0f0f0c000500000000000005000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101090e0e0a000406040405040404030101090e0e0a000000000000000000000101090e0e0a000404040504040604000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01000000584e540056484d5a0000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0100000000000000000000000000000101000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011200080062500000000000000000655000000000000000000000000000000000000060000000000000000000000000000000000000006000000000000000000000000000000000000000600000000000000000
011200201813218132181321813200605006000060018132131321313213132131320060500000000001313218132181321b13218132181321613216130181321313213132131321313200605000000000013132
01260000181321813218132181001b1321b1321b132000021d1321b1321b1001f1321f1321f1321f13218100181321813218102181321b1321b13203002181321d1321b1321b1001813218132181321813200000
012600040062500615006550062500600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200001365513605136550e6050b605096050960506605056050360501605006052940529405294050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
01120000181520000213102000021315200002000020000218152161520000218152131520000200002000021815216152181521b1021b152000021d152201021f1522210222152211021f1521f1520000200002
011200001f1521f1021f1521f1021d1521b152181521b1021b1521c1021d152211021a15218152161521810218152000021815200002131521815200002131521815218102131521815218102000021310218102
011200000c6350c6250c6550c6350c6350c6250c6550c6350c6350c6250c6550c6350c6350c6250c6550c6350c6350c6250c6550c6350c6350c6250c6550c6350c6350c6250c6550c6350c6350c6550c6550c655
__music__
03 01004344
03 02034344
01 05074344
02 06074344

