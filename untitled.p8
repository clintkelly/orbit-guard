pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
dust = {}

function dust:new()
	local obj = {
		x = rnd(127),
		y = 0,
		v = rnd(3),
		color = 7,
		radius = rnd(3),
	}
	setmetatable(obj,self)
	self.__index = self
	return obj
end

function dust:draw()
	circfill(self.x, self.y, self.radius, self.color)
end

function dust:update()
	self.y += self.v
	if self.y > 127 then self.y = -10 end
end

player = {}
function player:new(num)
	local obj = {
		x=63 + 10*num,
		y=63,
		sp=1,
		delay=10,
		frame=0,
		num=num
	}
	setmetatable(obj,self)
	self.__index = self
	return obj
end

function player:update()
	if btn(1, self.num) then
		self.x+=1
	end
	
	if btn(0, self.num) then
		self.x-=1
	end
	
	if btn(3, self.num) then
		self.y+=1
	end
	
	if btn(2, self.num) then
		self.y-=1
	end
	
	if self.x < 0 then self.x = 0 end
	if self.x > 127 then self.x = 127 end
	if self.y < 0 then self.y = 0 end
	if self.y > 127 then self.y = 127 end
	
	self.frame += 1
	if self.frame == self.delay then
		self.sp += 1
		self.frame=0
		if self.sp == 3 then
			self.sp = 1
		end
	end 
end	

function player:draw()
	spr(self.sp,self.x,self.y)
end

function _init()
	p0 = player:new(0)
	p1 = player:new(1)
end

function _update()
 -- move right --
	p0:update()
	p1:update()
end

function _draw()
	cls()
	p0:draw()
	p1:draw()
	print(
	"x: "..p0.x..
	" y: "..p0.y..
	" frame: "..p0.frame,
	 0, 0, 7)
	
end
__gfx__
00000000000000007000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007000000777eeee7700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070077eeee7700aeea0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000aeea0000e77e0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000e77e009888888900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700988888890008800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000880000008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
