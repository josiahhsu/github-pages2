pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
#include shared/gridhelpers.p8

function _init()
	cls()
	score = 0
	px = 1 //player x coordinate
	py = 1 //player y coordinate
	ps = nil //player stored cell
	pm = nil //moved cell
	size = 12 //size of grid
	set_grid(make_grid(),true)
	specials = {}
	bombs = {}
	wilds = {}
	lightnings = {}
	init_grid()
	game_active = true
end

function _update()
	controls()
end

function _draw()
	draw_grid()
	draw_pointer()
end

function wait(t)
	//waits for t frames
	for i = 0, t do
		flip()
	end
end
-->8
function make_cell(x,y)
	//creates a cell of a
	//random color at the
	//specified position
	local c = {}
	c.x = x
	c.y = y
	c.color = ceil(rnd(7))
	c.clear = false //color != 10
	c.special = false //color > 16

	make_plain(c)
	return c
end

function make_plain(cell)
	//removes special effects
	//from cells
	cell.color %= 8
	function cell:clear_cell()
		cell.clear = true
	end
end

function make_bomb(cell)
	//converts cell to bomb
	//of same color
	cell.clear = false
	cell.special = true
	cell.color = cell.color%16+16
	function cell:clear_cell()
		//blows up surrounding cells
		cell.clear = true
		local c = cell.x
		local r = cell.y
		if game_active then
			local x = (c-1) * 9 + 1
			local y = (r-1) * 9 + 6
			sfx(2)
			//animation
			for i = 1, 3 do
				spr(60+4*i,x,y,i,i)
				wait(1)
				draw_grid()
			end
			wait(1)
			cell_do_adj(c,r,clear)
		end
		make_plain(cell)
	end
end

function make_lightning(cell)
	//converts cell to lightning
	//cell of same color
	cell.clear = false
	cell.special = true
	cell.color = cell.color%16+32
	function cell:clear_cell()
		//blows up surrounding cells
		cell.clear = true
		local c = cell.x
		local r = cell.y
		if game_active then
			sfx(5)
			//animation
			spr(40,c*9+1,r*9+6)
			for i = 1, 12, 2 do
				spr(40,(c-i)*9+1,r*9+6)
				spr(40,(c+i)*9+1,r*9+6)
				spr(40,c*9+1,(r-i)*9+6)
				spr(40,c*9+1,(r+i)*9+6)
				wait(1)
				draw_grid()
			end

			cell_do_lane(r,true,clear)
			cell_do_lane(c,false,clear)
		end
		make_plain(cell)
	end
end

function make_wild(cell)
	//converts cell to wildcard
	cell.clear = false
	cell.wild = true
	cell.special = true
	cell.color = 0
	function cell:clear_cell()
		c2 = make_cell(-1,-1)
		wildcard(cell, c2)
	end
end

function make_grid()
	//initializes a grid of cells
	local grid = {}
	for i = 1, size do
		grid[i] = {}
		for j = 1, size do
			grid[i][j] = make_cell(i,j)
		end
	end
	return grid
end

function init_grid()
	//initializes the grid
	//at the start of the game
	removedwild = false
	while clear_cells()!=0 do end
	
	cell_do_all(
	function(x,y)
		make_plain(get_cell(x,y))
		if get_cell(x,y).color==0 then
			get_cell(x,y).color = 1
			removedwild = true
		end
	end
	)

	if removedwild then
		init_grid()
	end
end

function shuffle()
	//shuffles the board while
	//keeping current tiles
	print("shuffle!",90,2,6)
	wait(10)
	for c = 1, size do
		for r = 1, size do
			local x = ceil(rnd(size))
			local y = ceil(rnd(size))
			swap(get_cell(c,r),
			     get_cell(x,y))
		end
	end
	draw_grid()
	wait(10)
	update_grid()
end

function draw_grid()
	//displays the board
	rectfill(0,0,128,128,1)
	rectfill(9,14,117,122,15)
	cell_do_all(draw_cell)
	print("score: "..score,9,2,6)
end

function update_grid()
	//updates grid display and
	//returns # of changed cells

	local num = clear_cells()
	local p = 0 //cells cleared
	local c = 0 //level of chain
	while num != 0 do
		c += 1
		p += num
		draw_grid()
		print("chain: "..c.." x "..p,
		32,8,6)
		//waits so player can see
		//update during chain
		wait(10)
		num = clear_cells()
	end
	//+1 point per cell cleared
	//+1 multiplier per chain
	score += p * c
	return p
end

function draw_cell(x,y)
	//displays one cell
	local cell = get_cell(x,y)
	if not cell.clear then
		local x = cell.x*9+1
		local y = cell.y*9+6
		spr(cell.color,x,y)
	end
end
-->8
function controls()
	//moving the pointer and
	//controlling swaps
	if btnp(0) then
		move_pointer(-1,0)
	elseif btnp(1) then
		move_pointer(1,0)
	elseif btnp(2) then
		move_pointer(0,-1)
	elseif btnp(3) then
		move_pointer(0,1)
	end
	if btn(4) and btn(5) then
		//testing purposes only
		//make_wild(get_cell(px,py))
		//make_bomb(get_cell(px,py))
		//make_lightning(get_cell(px,py))
		//shuffle()
	elseif btnp(4) or btnp(5) then
		swap_action()
	end
end

function move_pointer(dx,dy)
	//moves the pointer
	local x = px + dx
	local y = py + dy

	//keeps in bounds
	if valid_move(x,y) then
		px = x
		py = y
		sfx(0)
	end
end

function valid_move(x,y)
	//checks to see if pointer
	//movement is valid
	local valid = in_bounds_x(x) and
	              in_bounds_y(y)

	//restricts movement to 1
	//square if cell selected
	if valid and ps then
		local hx = ps.x
		local hy = ps.y
		return
			abs(hx-x) <=1 and hy == y or
			abs(hy-y) <=1 and hx == x
	else
		return valid
	end
end

function draw_pointer()
	//shows the pointer
	local x = px*9+1
	local y = py*9+6
	spr(8,x,y)
	if ps then
		local hx = ps.x*9+1
		local hy = ps.y*9+6
		spr(9,hx,hy)
	end
end

function swap_action()
	//player initiated
	//cell swap
	local c = get_cell(px,py)
	if ps == nil then
		//stores a cell
		sfx(0)
		ps = c
	else
		//swaps selected cell
		if not (ps.x == c.x
		   and ps.y == c.y) then
			pm = c
			pc = ps.color
			cc = c.color
			if max(pc, cc) == 0 then
				//double wildcard
				clear_all()
			elseif min(pc, cc) == 0 then
				//wildcard
				draw_grid()
				wildcard(ps, c)
				sfx(1)
				wait(5)
				update_grid()
			else
				swap(ps, c)
				sfx(0)
				draw_grid()
				wait(5)
				if update_grid() == 0 then
				//invalid move
				sfx(0)
				swap(ps, c)
				end
			end
		else
			sfx(0)
		end
		ps = nil
		pm = nil
	end
end

function swap(c1, c2)
	//swaps two cells in the grid
	//and updates their x/y coords
	local x1, x2 = c1.x, c2.x
	local y1, y2 = c1.y, c2.y
	swap_cells(x1,y1,x2,y2)
	c1.x, c2.x = x2, x1
	c1.y, c2.y = y2, y1
end
-->8
function match(c1, c2)
	//checks if two cells are
	//considered a match
	//match = same color, not wild
	c = fget(c1)&fget(c2)
	return c != 0 and c != 128
end

function clear(x,y)
	clear_cell(get_cell(x,y))
end

function clear_cell(c)
	//clears normal cells, adds
	//special cells to table
	//to be detonated separately
	if c.special then
		add(specials, c)
	else
		c.clear_cell()
	end
end

function detonate()
	//detonates special cells
	for c in all(specials) do
		c.clear_cell()
	end
	specials = {}
end

function set_specials()
	//adding special gems from
	//matches, with higher level
	//gems taking priority

	foreach(bombs, make_bomb)
	bombs = {}
	foreach(lightnings, make_lightning)
	lightnings = {}
	foreach(wilds, make_wild)
	wilds = {}
end

function clear_cells()
	//checks for matches and
	//clears all cells
	local cl = false
	for i = 1, size do
		cl = check_lines(i) or cl
	end

	cleared =
	#bombs + #lightnings + #wilds

	detonate()
	set_specials()
	//allows for player to see
	//cleared cells
	if game_active and cl then
		sfx(1)
		draw_grid()
		wait(5)
	end
	
	cell_do_all(
	function(x,y)
		if get_cell(x,y).clear then
			//swaps cleared cell to top
			//and replaces it - "drop"
			cleared += 1
			for j = y, 2, -1 do
				local c1 = get_cell(x,j)
				local c2 = get_cell(x,j-1)
				swap(c1,c2)
			end
			set_cell(x,1,make_cell(x,1))
		end
	end
	)
	
	return cleared
end

function check_lines(l)
	//checks for 3 or more
	//matches in a line
	local cleared = false
	
	for isrow = 0, 1 do
		local cells = {}
		local cl = -1 //stored color
		
		//gets nth cell within a line
		local function get(n)
			if isrow == 0 then
				return get_cell(l,n)
			else
				return get_cell(n,l)
			end
		end
		
		local function check_match()
			//marks given col from
			//start index to end index
			local cnt = #cells
			if cnt >= 3 then
				cleared = true
				// get middle of match for
				// setting special cells
				local sp = flr(cnt/2)
				local special = cells[sp]
				for j = 1, cnt do
					local jcell = cells[j]
					// priority for moved cells
					// to become special
					if jcell == ps or
								jcell == pm then
						special = jcell
					end
					
					// detect intersection
					// for lightnings
					if jcell.clear then
						add(lightnings, jcell)
					else
						clear_cell(jcell)
					end
				end
				
				// generate special cells
				// based on match length
				if cnt == 4 then
					add(bombs, special)
				elseif cnt > 4 then
					add(wilds, special)
				end
			end
		end
		
		for i = 1, size do
			local cell = get(i)
			if not match(cell.color,cl) then
				check_match()
				cells = {}
				cl = cell.color
			end
			add(cells,cell)
		end
		// check at end
		check_match()
	end
	return cleared
end
-->8
function wildcard(c1,c2)
	//clears all cells matching
	//a given color

	//ensure c1 is wild
	if c2.color == 0 then
		c1, c2 = c2, c1
	end

	//clear c1
	c1.clear = true
	make_plain(c1)

	//clear all colors matching c2
	local c = c2.color
	local cells = {}
	cell_do_all(
	function(x,y)
		local cell = get_cell(x,y)
		if match(cell.color,c) then
			cell.color-=cell.color%16
			add(cells, cell)
			draw_cell(x,y)
		end
	end
	)

	sfx(4)
	wait(10)
	foreach(cells, clear_cell)
	detonate()
	draw_grid()
end

function clear_all()
	//double wildcards -
	//clears whole screen
	cell_do_all(
	function(x,y)
		get_cell(x,y).clear = true;
	end
	)
	
	sfx(3)
	print("screen clear!",38,8,6)
	for i = 0,10 do
		local cs = {8,9,10,11,12,14}
		local dx = i*9
		//animation
		for j = 1,6 do
			local y1 = -4+j*18
			local y2 = 14+j*18

			local ln = j % 2==1
			local x1 = ln and 9 or 117
			local x2 = ln and 27+dx or 99-dx
			rectfill(x1,y1,x2,y2,cs[j])
		end
		wait(1)
	end
	draw_grid()
	sfx(1)
	wait(5)
	update_grid()
end
__gfx__
00055000000550000005500000055000000550000005500000055000000550005555555522222222000550000000000000000000000000000000000000000000
005895000058850000599500005aa500005bb500005cc500005ee500005775005000000522200222005005000000000000000000000000000000000000000000
0589ab50058888500599995005aaaa5005bbbb5005cccc5005eeee50057777505000000522000022050000500000000000000000000000000000000000000000
589abce558888885599999955aaaaaa55bbbbbb55cccccc55eeeeee5577777755000000520000002500000050000000000000000000000000000000000000000
59abce7558888885599999955aaaaaa55bbbbbb55cccccc55eeeeee5577777755000000520000002500000050000000000000000000000000000000000000000
05bce750058888500599995005aaaa5005bbbb5005cccc5005eeee50057777505000000522000022050000500000000000000000000000000000000000000000
005e75000058850000599500005aa500005bb500005cc500005ee500005775005000000522200222005005000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550005555555522222222000550000000000000000000000000000000000000000000
00055019000550190005501900055019000550190005501900055019000550190000000000000000000000000000000000000000000000000000000000000000
005895100058851000599510005aa510005bb510005cc510005ee510005775100000000000000000000000000000000000000000000000000000000000000000
0589ab50058888500599995005aaaa5005bbbb5005cccc5005eeee50057777500000000000000000000000000000000000000000000000000000000000000000
58955ce558855885599559955aa55aa55bb55bb55cc55cc55ee55ee5577557750000000000000000000000000000000000000000000000000000000000000000
59a55e7558855885599559955aa55aa55bb55bb55cc55cc55ee55ee5577557750000000000000000000000000000000000000000000000000000000000000000
05bce750058888500599995005aaaa5005bbbb5005cccc5005eeee50057777500000000000000000000000000000000000000000000000000000000000000000
005e75000058850000599500005aa500005bb500005cc500005ee500005775000000000000000000000000000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550000000000000000000000000000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550000011000000000000000000000000000000000000000000000000000000000000
005815000058150000591500005a1500005b1500005c1500005e15000057150001aa101000000000000000000000000000000000000000000000000000000000
05891b50058818500599195005aa1a5005bb1b5005cc1c5005ee1e5005771750001aa1a100000000000000000000000000000000000000000000000000000000
511abce55118888551199995511aaaa5511bbbb5511cccc5511eeee55117777501aaaaa100000000000000000000000000000000000000000000000000000000
59abc11558888115599991155aaaa1155bbbb1155cccc1155eeee115577771151aaaaa1000000000000000000000000000000000000000000000000000000000
05b1e750058188500591995005a1aa5005b1bb5005c1cc5005e1ee50057177501a1aa10000000000000000000000000000000000000000000000000000000000
0051750000518500005195000051a5000051b5000051c5000051e500005175000101aa1000000000000000000000000000000000000000000000000000000000
00055000000550000005500000055000000550000005500000055000000550000000110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000000000000000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000000008800000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000008888000889800000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000088998888899980000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000889999999999980000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550088999999999999880000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550089999999999999800000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000888800880000000555555550089999999999999880000005555555500000000000000000000000000000000
00000000000800000000000055555555000000008899988980000000555555550089999999999999988000005555555500000000000000000000000000000000
00000000008988000000000055555555000000088999999980000000555555550889999aa9aaa999999880005555555500000000000000000000000000000000
00000000089999800000000055555555000000889999999880000000555555550899999aaaaaaa99999988005555555500000000000000000000000000000000
00000000899aa9800000000055555555000000899aaaa99800000000555555550899999aaaaaaa99999998805555555500000000000000000000000000000000
00000000089aa9800000000055555555000000899aaaa998800000005555555508999999aaaaaa99999999805555555500000000000000000000000000000000
00000000089999800000000055555555000000899aaaa9998000000055555555088999999aaaaaa9999999805555555500000000000000000000000000000000
0000000000899800000000005555555500000089999aa99980000000555555550088999999aa9999999998805555555500000000000000000000000000000000
00000000000880000000000055555555000000888999999880000000555555550008899999999999999998005555555500000000000000000000000000000000
00000000000000000000000055555555000000008898898800000000555555550000899999999999999880005555555500000000000000000000000000000000
00000000000000000000000055555555000000000888088000000000555555550000899999999999988800005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000899889999998880000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000888088899888000000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000088800000000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000000000000000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000000000000000005555555500000000000000000000000000000000
00000000000000000000000055555555000000000000000000000000555555550000000000000000000000005555555500000000000000000000000000000000
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116611661166166616661111111116661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161116111616161616111161111116161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166616111616166116611111111116161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111616111616161616111161111116161111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111166111661661161616661111111116661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5885fffff5995fffff5775fffff5885fffff5995fffff5cc5fffff5ee5fffff5775fffff5aa5fffff5775fffff5cc5fffff5995fff1111111111
111111111ff588885fff599995fff577775fff588885fff599995fff5cccc5fff5eeee5fff577775fff5aaaa5fff577775fff5cccc5fff599995ff1111111111
111111111f58888885f59999995f57777775f58888885f59999995f5cccccc5f5eeeeee5f57777775f5aaaaaa5f57777775f5cccccc5f59999995f1111111111
111111111f58888885f59999995f57777775f58888885f59999995f5cccccc5f5eeeeee5f57777775f5aaaaaa5f57777775f5cccccc5f59999995f1111111111
111111111ff588885fff599995fff577775fff588885fff599995fff5cccc5fff5eeee5fff577775fff5aaaa5fff577775fff5cccc5fff599995ff1111111111
111111111fff5885fffff5995fffff5775fffff5885fffff5995fffff5cc5fffff5ee5fffff5775fffff5aa5fffff5775fffff5cc5fffff5995fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5775fffff5cc5fffff5885fffff5ee5fffff5775fffff5995fffff5775fffff5bb5fffff5885fffff5775fffff5885fffff5885fff1111111111
111111111ff577775fff5cccc5fff588885fff5eeee5fff577775fff599995fff577775fff5bbbb5fff588885fff577775fff588885fff588885ff1111111111
111111111f57777775f5cccccc5f58888885f5eeeeee5f57777775f59999995f57777775f5bbbbbb5f58888885f57777775f58888885f58888885f1111111111
111111111f57777775f5cccccc5f58888885f5eeeeee5f57777775f59999995f57777775f5bbbbbb5f58888885f57777775f58888885f58888885f1111111111
111111111ff577775fff5cccc5fff588885fff5eeee5fff577775fff599995fff577775fff5bbbb5fff588885fff577775fff588885fff588885ff1111111111
111111111fff5775fffff5cc5fffff5885fffff5ee5fffff5775fffff5995fffff5775fffff5bb5fffff5885fffff5775fffff5885fffff5885fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5bb5fffff5bb5fffff5ee5fffff5775fffff5775fffff5885fffff5775fffff5775fffff5885fffff5995fffff5aa5fffff5aa5fff1111111111
111111111ff5bbbb5fff5bbbb5fff5eeee5fff577775fff577775fff588885fff577775fff577775fff588885fff599995fff5aaaa5fff5aaaa5ff1111111111
111111111f5bbbbbb5f5bbbbbb5f5eeeeee5f57777775f57777775f58888885f57777775f57777775f58888885f59999995f5aaaaaa5f5aaaaaa5f1111111111
111111111f5bbbbbb5f5bbbbbb5f5eeeeee5f57777775f57777775f58888885f57777775f57777775f58888885f59999995f5aaaaaa5f5aaaaaa5f1111111111
111111111ff5bbbb5fff5bbbb5fff5eeee5fff577775fff577775fff588885fff577775fff577775fff588885fff599995fff5aaaa5fff5aaaa5ff1111111111
111111111fff5bb5fffff5bb5fffff5ee5fffff5775fffff5775fffff5885fffff5775fffff5775fffff5885fffff5995fffff5aa5fffff5aa5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55ffff55555555ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5aa5fffff5885fffff5885fff5f5bb5f5fff5cc5fffff5775fffff5995fffff5995fffff5775fffff5885fffff5aa5fffff5995fff1111111111
111111111ff5aaaa5fff588885fff588885ff55bbbb55ff5cccc5fff577775fff599995fff599995fff577775fff588885fff5aaaa5fff599995ff1111111111
111111111f5aaaaaa5f58888885f58888885f5bbbbbb5f5cccccc5f57777775f59999995f59999995f57777775f58888885f5aaaaaa5f59999995f1111111111
111111111f5aaaaaa5f58888885f58888885f5bbbbbb5f5cccccc5f57777775f59999995f59999995f57777775f58888885f5aaaaaa5f59999995f1111111111
111111111ff5aaaa5fff588885fff588885ff55bbbb55ff5cccc5fff577775fff599995fff599995fff577775fff588885fff5aaaa5fff599995ff1111111111
111111111fff5aa5fffff5885fffff5885fff5f5bb5f5fff5cc5fffff5775fffff5995fffff5995fffff5775fffff5885fffff5aa5fffff5995fff1111111111
111111111ffff55fffffff55fffffff55ffff55555555ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5775fffff5cc5fffff5995fffff5aa5fffff5cc5fffff5885fffff5cc5fffff5ee5fffff5bb5fffff5cc5fffff5ee5fffff5995fff1111111111
111111111ff577775fff5cccc5fff599995fff5aaaa5fff5cccc5fff588885fff5cccc5fff5eeee5fff5bbbb5fff5cccc5fff5eeee5fff599995ff1111111111
111111111f57777775f5cccccc5f59999995f5aaaaaa5f5cccccc5f58888885f5cccccc5f5eeeeee5f5bbbbbb5f5cccccc5f5eeeeee5f59999995f1111111111
111111111f57777775f5cccccc5f59999995f5aaaaaa5f5cccccc5f58888885f5cccccc5f5eeeeee5f5bbbbbb5f5cccccc5f5eeeeee5f59999995f1111111111
111111111ff577775fff5cccc5fff599995fff5aaaa5fff5cccc5fff588885fff5cccc5fff5eeee5fff5bbbb5fff5cccc5fff5eeee5fff599995ff1111111111
111111111fff5775fffff5cc5fffff5995fffff5aa5fffff5cc5fffff5885fffff5cc5fffff5ee5fffff5bb5fffff5cc5fffff5ee5fffff5995fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5bb5fffff5885fffff5885fffff5775fffff5775fffff5cc5fffff5885fffff5885fffff5bb5fffff5775fffff5cc5fffff5bb5fff1111111111
111111111ff5bbbb5fff588885fff588885fff577775fff577775fff5cccc5fff588885fff588885fff5bbbb5fff577775fff5cccc5fff5bbbb5ff1111111111
111111111f5bbbbbb5f58888885f58888885f57777775f57777775f5cccccc5f58888885f58888885f5bbbbbb5f57777775f5cccccc5f5bbbbbb5f1111111111
111111111f5bbbbbb5f58888885f58888885f57777775f57777775f5cccccc5f58888885f58888885f5bbbbbb5f57777775f5cccccc5f5bbbbbb5f1111111111
111111111ff5bbbb5fff588885fff588885fff577775fff577775fff5cccc5fff588885fff588885fff5bbbb5fff577775fff5cccc5fff5bbbb5ff1111111111
111111111fff5bb5fffff5885fffff5885fffff5775fffff5775fffff5cc5fffff5885fffff5885fffff5bb5fffff5775fffff5cc5fffff5bb5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5885fffff5aa5fffff5775fffff5bb5fffff5ee5fffff5aa5fffff5885fffff5cc5fffff5775fffff5775fffff5995fffff5ee5fff1111111111
111111111ff588885fff5aaaa5fff577775fff5bbbb5fff5eeee5fff5aaaa5fff588885fff5cccc5fff577775fff577775fff599995fff5eeee5ff1111111111
111111111f58888885f5aaaaaa5f57777775f5bbbbbb5f5eeeeee5f5aaaaaa5f58888885f5cccccc5f57777775f57777775f59999995f5eeeeee5f1111111111
111111111f58888885f5aaaaaa5f57777775f5bbbbbb5f5eeeeee5f5aaaaaa5f58888885f5cccccc5f57777775f57777775f59999995f5eeeeee5f1111111111
111111111ff588885fff5aaaa5fff577775fff5bbbb5fff5eeee5fff5aaaa5fff588885fff5cccc5fff577775fff577775fff599995fff5eeee5ff1111111111
111111111fff5885fffff5aa5fffff5775fffff5bb5fffff5ee5fffff5aa5fffff5885fffff5cc5fffff5775fffff5775fffff5995fffff5ee5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5775fffff5ee5fffff5995fffff5cc5fffff5cc5fffff5995fffff5cc5fffff5995fffff5ee5fffff5885fffff5cc5fffff5995fff1111111111
111111111ff577775fff5eeee5fff599995fff5cccc5fff5cccc5fff599995fff5cccc5fff599995fff5eeee5fff588885fff5cccc5fff599995ff1111111111
111111111f57777775f5eeeeee5f59999995f5cccccc5f5cccccc5f59999995f5cccccc5f59999995f5eeeeee5f58888885f5cccccc5f59999995f1111111111
111111111f57777775f5eeeeee5f59999995f5cccccc5f5cccccc5f59999995f5cccccc5f59999995f5eeeeee5f58888885f5cccccc5f59999995f1111111111
111111111ff577775fff5eeee5fff599995fff5cccc5fff5cccc5fff599995fff5cccc5fff599995fff5eeee5fff588885fff5cccc5fff599995ff1111111111
111111111fff5775fffff5ee5fffff5995fffff5cc5fffff5cc5fffff5995fffff5cc5fffff5995fffff5ee5fffff5885fffff5cc5fffff5995fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5885fffff5995fffff5bb5fffff5885fffff5aa5fffff5aa5fffff5995fffff5aa5fffff5885fffff5bb5fffff5aa5fffff5ee5fff1111111111
111111111ff588885fff599995fff5bbbb5fff588885fff5aaaa5fff5aaaa5fff599995fff5aaaa5fff588885fff5bbbb5fff5aaaa5fff5eeee5ff1111111111
111111111f58888885f59999995f5bbbbbb5f58888885f5aaaaaa5f5aaaaaa5f59999995f5aaaaaa5f58888885f5bbbbbb5f5aaaaaa5f5eeeeee5f1111111111
111111111f58888885f59999995f5bbbbbb5f58888885f5aaaaaa5f5aaaaaa5f59999995f5aaaaaa5f58888885f5bbbbbb5f5aaaaaa5f5eeeeee5f1111111111
111111111ff588885fff599995fff5bbbb5fff588885fff5aaaa5fff5aaaa5fff599995fff5aaaa5fff588885fff5bbbb5fff5aaaa5fff5eeee5ff1111111111
111111111fff5885fffff5995fffff5bb5fffff5885fffff5aa5fffff5aa5fffff5995fffff5aa5fffff5885fffff5bb5fffff5aa5fffff5ee5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5775fffff5cc5fffff5995fffff5775fffff5bb5fffff5cc5fffff5cc5fffff5995fffff5cc5fffff5885fffff5bb5fffff5775fff1111111111
111111111ff577775fff5cccc5fff599995fff577775fff5bbbb5fff5cccc5fff5cccc5fff599995fff5cccc5fff588885fff5bbbb5fff577775ff1111111111
111111111f57777775f5cccccc5f59999995f57777775f5bbbbbb5f5cccccc5f5cccccc5f59999995f5cccccc5f58888885f5bbbbbb5f57777775f1111111111
111111111f57777775f5cccccc5f59999995f57777775f5bbbbbb5f5cccccc5f5cccccc5f59999995f5cccccc5f58888885f5bbbbbb5f57777775f1111111111
111111111ff577775fff5cccc5fff599995fff577775fff5bbbb5fff5cccc5fff5cccc5fff599995fff5cccc5fff588885fff5bbbb5fff577775ff1111111111
111111111fff5775fffff5cc5fffff5995fffff5775fffff5bb5fffff5cc5fffff5cc5fffff5995fffff5cc5fffff5885fffff5bb5fffff5775fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5bb5fffff5cc5fffff5cc5fffff5885fffff5995fffff5885fffff5775fffff5775fffff5995fffff5775fffff5aa5fffff5cc5fff1111111111
111111111ff5bbbb5fff5cccc5fff5cccc5fff588885fff599995fff588885fff577775fff577775fff599995fff577775fff5aaaa5fff5cccc5ff1111111111
111111111f5bbbbbb5f5cccccc5f5cccccc5f58888885f59999995f58888885f57777775f57777775f59999995f57777775f5aaaaaa5f5cccccc5f1111111111
111111111f5bbbbbb5f5cccccc5f5cccccc5f58888885f59999995f58888885f57777775f57777775f59999995f57777775f5aaaaaa5f5cccccc5f1111111111
111111111ff5bbbb5fff5cccc5fff5cccc5fff588885fff599995fff588885fff577775fff577775fff599995fff577775fff5aaaa5fff5cccc5ff1111111111
111111111fff5bb5fffff5cc5fffff5cc5fffff5885fffff5995fffff5885fffff5775fffff5775fffff5995fffff5775fffff5aa5fffff5cc5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fff5ee5fffff5ee5fffff5995fffff5885fffff5cc5fffff5bb5fffff5885fffff5ee5fffff5775fffff5ee5fffff5995fffff5ee5fff1111111111
111111111ff5eeee5fff5eeee5fff599995fff588885fff5cccc5fff5bbbb5fff588885fff5eeee5fff577775fff5eeee5fff599995fff5eeee5ff1111111111
111111111f5eeeeee5f5eeeeee5f59999995f58888885f5cccccc5f5bbbbbb5f58888885f5eeeeee5f57777775f5eeeeee5f59999995f5eeeeee5f1111111111
111111111f5eeeeee5f5eeeeee5f59999995f58888885f5cccccc5f5bbbbbb5f58888885f5eeeeee5f57777775f5eeeeee5f59999995f5eeeeee5f1111111111
111111111ff5eeee5fff5eeee5fff599995fff588885fff5cccc5fff5bbbb5fff588885fff5eeee5fff577775fff5eeee5fff599995fff5eeee5ff1111111111
111111111fff5ee5fffff5ee5fffff5995fffff5885fffff5cc5fffff5bb5fffff5885fffff5ee5fffff5775fffff5ee5fffff5995fffff5ee5fff1111111111
111111111ffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55fffffff55ffff1111111111
111111111fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
8001020408102040000000000000000080010204081020400000000000000000800102040810204000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002104020040200400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000260302a0302f0303000031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002963026630216301d63017630126300d63009630046300063007600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000d040100400e0400d0400a0400e04013040120401104017040190401a040170401604016040180401a0401e0402104026040290402b0402f040340403804000000000000000000000000000000000000
000200001d0401c0401c0401d0401d0401f04021040240402504027040290402d0402f0402f040220002200024000250002600026000000000000000000000000000000000000000000000000000000000000000
000300002b6301b6301163007630286302a6302c6302863025630206301b63016630116300a6300863005630036300060005600056000560020600176000a6000f60015600196000f6000960008600096000a600
