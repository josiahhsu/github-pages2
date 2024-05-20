pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
	cls()

	// grid size and # of mines
	m,n = 18,14

	grid = make_grid()

	// player position
	px,py = 1,1

	t = 0
	dur = 10
	gen = 0
	state = edit_state()
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
function make_cell(x,y)
	//makes a cell and determines
	//whether it's marked or not
	local cell = {}
	cell.x = x
	cell.y = y
	cell.spr = 0
	cell.live = false
	cell.nextlive = false
	
	function cell:toggle()
		cell.live = not cell.live
		cell.spr = cell.live and 1 or 0
	end
	
	function cell:update()
		local x,y,cnt=cell.x,cell.y,0
		for i = x-1,x+1 do
			for j = y-1,y+1 do
				if in_bounds(i,j) and
				   not (i == x and j == y) and
				   grid[i][j].live then
					cnt += 1
				end
			end
		end
		
		if (cell.live and cnt == 2)
		   or cnt == 3 then
			cell.nextlive = true
		else
			cell.nextlive = false
		end
	end
	
	function cell:transition()
		cell.live = cell.nextlive
		cell.spr = cell.live and 1 or 0
	end
	return cell
end

function make_grid()
	//makes grid of cells
	local grid = {}
	for i = 1, m do
		grid[i] = {}
		for j = 1, n do
			grid[i][j] = make_cell(i,j)
		end
	end
	return grid
end
-->8
function controls()
	//player controls for movement
	//and revealing cells
	if btnp(0) then
		state.left()
	elseif btnp(1) then
		state.right()
	elseif btnp(2) then
		state.down()
	elseif btnp(3) then
		state.up()
	end

	if btnp(4) then
		state.z()
	elseif btnp(5) then
		state.o()
	end
end

// standard o button:
// flag or reveal adjacent
function o()
	if grid[px][py].opened then
		open_adjacent()
	else
		flag_cell()
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

function in_range(s,e,v)
	return s <= v and v <= e
end

function in_bounds_x(x)
	return in_range(1,m,x)
end

function in_bounds_y(y)
	return in_range(1,n,y)
end

function in_bounds(x,y)
	return in_bounds_x(x) and
	       in_bounds_y(y)
end

// wrappers for cell functions.
// only perform function if
// position is in bounds.
function cell_do(x,y,f)
	if in_bounds(x,y) then
		f(x,y)
	end
end

function cell_do_area(a,f)
	local x1,x2,y1,y2 = unpack(a)
	for i=x1,x2 do
		for j=y1,y2 do
			cell_do(i,j,f)
		end
	end
end

function cell_do_all(f)
	cell_do_area({1,m,1,n},f)
end

-->8
function coords(x,y)
	//translates value to partial
	//position on grid
	return (x-1)*7,y*7+18
end

function draw_stats()
	rectfill(0,0,126,24,7)
	line(35,0,35,24,5)
	line(91,0,91,24,5)
	print("gen:"..gen,94,1,5)
	print("gen/s:",94,8,5)
	print(30/dur,94,15,5)
end

function draw_grid()
	//draws grid and info text
	rectfill(0,0,126,128,7)
	draw_stats()
	print("⬆️",13,4,5)
	print("⬅️⬇️➡️",5,10,5)
	print("to move",3,16,5)
	print("🅾️ to",38,1,5)
	print("toggle cells",38,7,5)
	print("❎ to start",38,13,5)
	print("or stop game",38,19,5)

	cell_do_all(
	function(x,y)
		//draws cells on grid
		local sx,sy = coords(x,y)
		spr(grid[x][y].spr,sx,sy)
	end
	)
end

function draw_pointer()
	//draws pointer position
	local x,y = coords(px,py)
	rect(x,y,x+7,y+7,9)
end

-->8
function edit_state()
	// before start of game
	local s = {}

	function s.update() end

	function s.draw()
		draw_pointer()
	end

	function s.left()
		move_horz(-1)
	end

	function s.right()
		move_horz(1)
	end

	function s.up()
		move_vert(1)
	end

	function s.down()
		move_vert(-1)
	end

	function s.z()
		grid[px][py].toggle()
	end

	function s.o()
		state = play_state()
	end

	return s
end

function play_state()
	// during main gameplay
	local s = {}

	function s.update()
		local old = t
		t+=1
		if t == dur then
			gen+=1
			t = 0
			cell_do_all(
			function(x,y)
				grid[x][y].update()
			end
			)
			
			cell_do_all(
			function(x,y)
				grid[x][y].transition()
			end
			)
		end
	end

	function s.draw()
		
	end

	function s.left()
		if (dur < 30) then
			dur += 1
			t = 0
		end
	end

	function s.right()
		if (dur > 1) then
			dur -= 1
			t = 0
		end
	end

	function s.up()
		
	end

	function s.down()
		
	end

	function s.z()
		
	end

	function s.o()
		state = edit_state()
	end

	return s
end
__gfx__
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd55aaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555555555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
77777777777777777777777777777777777577777777777777777777777777777777777777777777777777777775777777777777777777777777777777777770
77777777777777777777777777777777777577755555777777555775577777777777777777777777777777777775777557555755577557555777775557777770
77777777777777777777777777777777777577557775577777757757577777777777777777777777777777777775775777757757575777577775775757777770
77777777777777777777777777777777777577557575577777757757577777777777777777777777777777777775775557757755575777557777775557777770
77777777777777555557777777777777777577557775577777757757577777777777777777777777777777777775777757757757575757577775777757777770
77777777777775557555777777777777777577755555777777757755777777777777777777777777777777777775775577757757575557555777777757777770
77777777777775577755777777777777777577777777777777777777777777777777777777777777777777777775777777777777777777777777777777777770
77777777777775577755777777777777777577555775577557755757775557777775575557577757777557777775777777777777777777777777777777777770
77777777777777555557777777777777777577757757575777577757775777777757775777577757775777777775777777777777777777777777777777777770
77777777777777777777777777777777777577757757575777577757775577777757775577577757775557777775777777777777777777777777777777777770
77777755555777555557775555577777777577757757575757575757775777777757775777577757777757777775777777777777777777777777777777777770
77777555775575577755755775557777777577757755775557555755575557777775575557555755575577777775777777777777777777777777777777777770
77777557775575577755755777557777777577777777777777777777777777777777777777777777777777777775777777777777777777777777777777777770
77777555775575557555755775557777777577755555777777555775577777755755575557555755577777777775777777777777777777777777777777777770
77777755555777555557775555577777777577557575577777757757577777577775775757575775777777777775777777777777777777777777777777777770
77777777777777777777777777777777777577555755577777757757577777555775775557557775777777777775777777777777777777777777777777777770
77755577557777755577557575755577777577557575577777757757577777775775775757575775777777777775777777777777777777777777777777777770
77775775757777755575757575757777777577755555777777757755777777557775775757575775777777777775777777777777777777777777777777777770
77775775757777757575757575755777777577777777777777777777777777777777777777777777777777777775777777777777777777777777777777777770
77775775757777757575757555757777777577755755577777755755577557555777777557555755575557777775777777777777777777777777777777777770
77775775577777757575577757755577777577575757577777577775775757575777775777575755575777777775777777777777777777777777777777777770
77777777777777777777777777777777777577575755777777555775775757555777775777555757575577777775777777777777777777777777777777777770
77777777777777777777777777777777777577575757577777775775775757577777775757575757575777777775777777777777777777777777777777777770
77777777777777777777777777777777777577557757577777557775775577577777775557575757575557777775777777777777777777777777777777777770
77777777777777777777777777777777777577777777777777777777777777777777777777777777777777777775777777777777777777777777777777777770
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5aaaaaa5dddddd5aaaaaa5aaaaaa5aaaaaa5aaaaaa5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5aaaaaa5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5aaaaaa5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd5dddddd50
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777770

