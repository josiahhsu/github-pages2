pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include shared/gridhelpers.p8

function _init()
	cls()
	// grid size
	m,n = 16,13
	set_grid(make_grid(),true)
	
	// player x/y pos,ins,oct
	px,py,pi,po = 1,1,0,1
	
	notes ={"b#","b","a#","a",
	        "g#","g","f#","f",
	        "e","d#","d","c#","c"}
	speed = 5
	
	state = note_state()
end

function _update()
	controls()
	state.update()
end

function _draw()
	draw_grid()
	state.draw()
end
-->8
function make_cell()
	//makes a cell
	local cell = {}
	cell.spr = -1
	cell.oct = -1
	return cell
end

function shuffle(t)
	for i = 1, #t do
		local j = rand_int(i)
		t[i],t[j] = t[j],t[i]
	end
end

function make_grid()
	local grid = {}
	for i = 1, m do
		grid[i] = {}
		for j = 1, n do
			grid[i][j] = make_cell()
		end
	end
	return grid
end
-->8
function controls()
	//player controls
	if btn(❎) then
		if btnp(⬅️) then
			state = note_state()
		elseif btnp(➡️) then
			state = select_state()
		elseif btnp(⬆️) then
			t = tempo
			state = play_state()
		end
		return
	end
	
	if btnp(⬅️) then
		state.left()
	elseif btnp(➡️) then
		state.right()
	elseif btnp(⬆️) then
		state.up()
	elseif btnp(⬇️) then
		state.down()
	end

	if btnp(🅾️) then
		state.o()
	end
end

function move_horz(dx)
	if in_bounds_x(px+dx) then
		px += dx
	end
end

function move_vert(dy)
	if in_bounds_y(py+dy) then
		py += dy
	end
end
-->8
function coords(x,y)
	//translates value to partial
	//position on grid
	return (x-1)*7+2,y*7
end

function draw_grid()
	rectfill(0,0,126,128,1)
	draw_state()
	print("⬆️⬇️⬅️➡️+❎ "..
	      "to change controls",
	      1,122,7)
	for i=0,8 do
		spr(i,115,i*7+7)
	end
	print("oct\n "..po,115,66,7)
	print("spd\n "..speed,115,80,7)
	rect(115,pi*7+7,122,pi*7+14,9)
	
	cell_do_all(
	function(x,y)
		//draws cells on grid
		spr(16, coords(x,y))
		spr(get_cell(x,y).spr,coords(x,y))
	end
	)
end

function draw_pointer()
	//draws pointer position
	local x,y = coords(px,py)
	rect(x,y,x+7,y+7,9)
end

function play(x,y)
	local c = get_cell(x,y)
	local i,n,o = c.spr,notes[y],c.oct
	if i >= 0 then
		print("\asfi"..i..n..o)
	end
end
-->8
function draw_state()
	print(state.name.." state",1,1,7)
end

function note_state()
	local s = {}
	s.name="note"
	function s.update() end

	function s.draw()
		print("⬆️⬇️⬅️➡️ to move",25,101,7)
		print("🅾️ to place/erase note",13,108,7)
		draw_pointer()
	end
	
	function s.left()
		move_horz(-1)
	end
	
	function s.right()
		move_horz(1)
	end
	
	function s.up()
		move_vert(-1)
	end
	
	function s.down()
		move_vert(1)
	end
	
	function s.o()
		local cell = get_cell(px,py)
		if cell.spr == pi then
			cell.spr = -1
		else
			cell.spr = pi
			cell.oct = po
			play(px,py)
		end
	end

	return s
end

function select_state()
	local s = {}
	s.name = "select"
	function s.update() end

	function s.draw()
		print("⬆️⬇️ to change instrument",13,101,7)
		print("⬅️➡️ to change octave",13,108,7)
		draw_pointer()
	end
	
	function s.left() 
		if po > 0 then
			po -= 1
		end
	end
	
	function s.right()
		if po < 4 then
			po += 1
		end
	end
	
	function s.up()
		if pi > 0 then
			pi -=1
		end
	end
	
	function s.down()
		if pi < 7 then
			pi += 1
		end
	end
	
	function s.o() end

	return s
end

function play_state()
	local s = {}
	s.name="playback"
	s.t = 0
	s.next = 1
	s.playing = false
	
	function s.update()
		if not s.playing then
			return
		end
		
		if s.t % speed == 0 then
			cell_do_lane(s.next,false,play)
			if s.next == m then
				s.playing = false
			else
				s.next+=1
			end
		end
		
		s.t+=1
	end
	
	function s.draw()
		local offset = (s.next-1)*7
		local col = s.playing and 8 or 9
		rect(2+offset,7,9+offset,98,col)
		print("🅾️ to start/stop",17,101,7)
		print("⬆️⬇️ to change tempo",13,108,7)
		print("⬅️➡️ to change position",13,115,7)
	end
	function s.left()
		if s.next > 1 then
			s.next -= 1
		end
	end
	function s.right()
		if s.next < m then
			s.next += 1
		end
	end
	function s.up()
		if speed < 30 then
			speed += 1
		end
	end
	function s.down()
		if speed > 1 then
			speed -= 1
		end
	end
	function s.o()
		s.playing = not s.playing
	end
	
	return s
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550000000000000000000000000000000000000000000000000000000000000000000
0058850000599500005aa500005bb500005cc500005dd500005ee500005ff5000000000000000000000000000000000000000000000000000000000000000000
0058850000599500005aa500005bb500005cc500005dd500005ee500005ff5000000000000000000000000000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
56666665000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
17711177177717771111117717771777177717771111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
17171717117117111111171111711717117117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
17171717117117711111177711711777117117711111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
17171717117117111111111711711717117117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
17171771117117771111177111711717117117771111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651158851111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651158851111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651159951111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651159951111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665665566566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
1156666665666666565dd5656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115aa51111110
1156666665666666565dd5656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115aa51111110
11566666656666665665566566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115bb51111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115bb51111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115cc51111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115cc51111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559999999911110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666659111111911110
11566556656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666659115511911110
11565dd565666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665915dd51911110
11565dd565666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665915dd51911110
11566556656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666659115511911110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666659111111911110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555559999999911110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115ee51111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665115ee51111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665665566566666656666665666666566666656666665666666566666656666665666666566666651115511111110
1156666665666666566666656666665666666565dd5656666665666666566666656666665666666566666656666665666666566666656666665115ff51111110
1156666665666666566666656666665666666565dd5656666665666666566666656666665666666566666656666665666666566666656666665115ff51111110
11566666656666665666666566666656666665665566566666656666665666666566666656666665666666566666656666665666666566666651115511111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555999999995555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666651771177177710
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666657171711117110
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666657171711117110
11566666656666665666666566666656666665666666566666656666665666666966666696666665666666566666656666665666666566666657171711117110
11555555555555555555555555555555555555555555555555555555555555555999999995555555555555555555555555555555555555555557711177117110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111777111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111117111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111777111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111711111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111777111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665665566566666656666665666666566666651111111111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666565dd56566666656666665666666566666651111111111110
1156666665666666566666656666665666666566666656666665666666566666656666665666666565dd56566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665665566566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665665566566666656666665666666566666656666665666666566666651111111111110
1156666665666666566666656666665666666566666656666665666666565dd56566666656666665666666566666656666665666666566666651111111111110
1156666665666666566666656666665666666566666656666665666666565dd56566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665665566566666656666665666666566666656666665666666566666651111111111110
11566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666656666665666666566666651111111111110
11555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555551111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111777771111111111111111111111111111111111111111111111111111111777771111117771177111117771711177711771777111111111110
11111111111117771777111111111111111111111111111111111111111111111111111117711177111111711717111117171711171717111711111111111110
11111111111117711177111111111111111111111111111111111111111111111111111117717177111111711717111117771711177717111771111111111110
11111111111117711177111111111177711771111177711771717177711111111111111117711177111111711717111117111711171717111711111111111110
11111111111111777771111111111117117171111177717171717171111111111111111111777771111111711771111117111777171711771777111111111110
11111111111111111111111111111117117171111171717171717177111111111111111111111111111111111111111111111111111111111111111111111110
11111177777111777771117777711117117171111171717171777171111111111111111771777111117771777177711771777111117711177177717771111110
11111777117717711177177117771117117711111171717711171177711111111111117171717111117111717171717111711111117171717117117111111110
11111771117717711177177111771111111111111111111111111111111111111111117171771111117711771177717771771111117171717117117711111110
11111777117717771777177117771111111111111111111111111111111111111111117171717111117111717171711171711111117171717117117111111110
11111177777111777771117777711111111111111111111111111111111111111111117711717111117771717171717711777111117171771117117771111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11777771117777711177777111777771111111777771111117771177111111771717177717711177177711111177117717711777177711771711117711111110
17771777177111771777117717711777117117717177111111711717111117111717171717171711171111111711171717171171171717171711171111111110
17711177177111771771117717711177177717771777111111711717111117111777177717171711177111111711171717171171177117171711177711111110
17711177177717771777117717711777117117717177111111711717111117111717171717171717171111111711171717171171171717171711111711111110
11777771117777711177777111777771111111777771111111711771111111771717171717171777177711111177177117171171171717711777177111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110

__sfx__
001700000000021000210002100021000210002100022000220002200022000000002200022000220002200000000000002200000000220002300000000230000000024000240002500000000250002500026000
011200000010000100001000010000100001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000020000200002000020000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000030000300003000030000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000040000400004000040000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000050000500005000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000060000600006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200000070000700007000070000700007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
