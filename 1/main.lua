-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function math.checkIntersect(l1p1, l1p2, l2p1, l2p2)
    local function checkDir(pt1, pt2, pt3) return math.sign(((pt2[1]-pt1[1])*(pt3[2]-pt1[2])) - ((pt3[1]-pt1[1])*(pt2[2]-pt1[2]))) end
    return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end
-- Gets the intersection 
function math.getIntercept(l1p1, l1p2, l2p1, l2p2)
	local m1 = (l1p2[2]-l1p1[2])/(l1p2[1]-l1p1[1])
	local m2 = (l2p2[2]-l2p1[2])/(l2p2[1]-l2p1[1])
	local b1 = -m1*l1p1[1]+l1p1[2]
	local b2 = -m2*l2p1[1]+l2p1[2]
	local x
	if l1p2[1] == l1p1[1] then
		x = l1p2[1] 
		return x, m2*x+b2
	elseif l2p2[1] == l2p1[1] then
		x = l2p2[1]
		return x, m1*x+b1
	else
		x = (b2-b1)/(m1-m2)
		return x, m1*x+b1
	end
end
-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function math.sign(n) return n>0 and 1 or n<0 and -1 or 0 end
function math.atan3(y1,y2,x1,x2)
	if y2 > y1 then
		return math.atan2(y2-y1,x2-x1)
	else
		return math.atan2(y1-y2,x1-x2)
	end
end
-- Deflect vec2 on vec1
function math.deflect(vec1,vec2)
		local phi = math.atan3(vec1[4],vec1[2],vec1[3],vec1[1])
		local theta = math.atan3(vec2[4], vec2[2], vec2[3], vec2[1]) - 2*phi

		if vec2[4] > vec2[2] then 
			theta = theta - math.pi
		end

		return math.cos(theta), -math.sin(theta)
end
-- Returns the distance between two points.
function math.dist(x1,y1, x2,y2) return ((x2-x1)^2+(y2-y1)^2)^0.5 end
--freeze for 
function freeze(s) local b = love.timer.getTime(); while love.timer.getTime() - b < s do end end

ball = {}
ball.__index = ball

function ball.make(x,y,iV)
	local b = {}
	setmetatable(b, ball)

	b.x, b.y = x ,y
	b._x, b._y = b.x, b.y
	b.norm = 0
	b.speed = 10
	b.forces = {iV}
	b.vec = {0,0} --<-- I think it looks like an owl
	b.gravity = .565

	b.color = {math.random(128,255),math.random(128,255),math.random(128,255)}

	b.trail = {}

	b.kill = false

	return b
end

function ball:draw()
	for i=1, #self.trail do
		love.graphics.setColor(255,255,255,255* i/#self.trail)
		love.graphics.setLineWidth(8* i/#self.trail)
		local x,y = unpack(self.trail[i+1] or {self.x, self.y})
		love.graphics.line(x,y,unpack(self.trail[i]))
	end
	love.graphics.setLineWidth(1)

	love.graphics.setColor(unpack(self.color))
	love.graphics.circle("fill",self.x, self.y, 6, 12)
end

function ball:update(dt)
	dt = dt*self.speed

	for i=1, #self.forces do
		self.vec[1] = self.vec[1] + math.cos(self.forces[i][1])*self.forces[i][2]
		self.vec[2] = self.vec[2] + math.sin(self.forces[i][1])*self.forces[i][2]
	end
	self.forces = {}

	self.trail[#self.trail+1] = {self._x,self._y}
	if #self.trail > 6 then
		table.remove(self.trail,1)
	end
	self._x, self._y = self.x, self.y
	self.x = self.x + self.vec[1]*dt
	self.y = self.y + self.vec[2]*dt

	-- if self.vec[1] ~= 0 then self.vec[1] = self.vec[1] - self.vec[1] / (99 * dt) end
	-- if self.vec[1] ~= 0 then self.vec[1] = self.vec[1] - self.vec[1]* self.speed/6000 end
	-- print(self.speed/6000)
	if math.abs(self.vec[1]) < .001 then self.vec[1] = 0 end
	if math.abs(self.vec[2]) < .001 then self.vec[2] = 0 end
	-- self.vec[2] = self.vec[2] + (self.gravity/(.01*dt)) * self.speed
	-- self.vec[2] = self.vec[2] + self.gravity / self.speed

	--collision
	for i=1, #bodies do
		local b = bodies[i]
		if math.checkIntersect({self.x,self.y},{self._x,self._y},b[1],b[2]) then
			-- local z = math.max((self.vec[1]^2 + self.vec[2]^2)^(0.5) * (b[3] or 1), 18)
			local z = math.max((self.vec[1]^2 + self.vec[2]^2)^(0.5) + .2, 18)
			local deflection = {math.deflect({b[1][1],b[1][2],b[2][1],b[2][2]},{self.x,self.y,self._x,self._y})}
			self.vec[1], self.vec[2] = z*deflection[1], z*deflection[2]
			self.x, self.y = math.getIntercept({self.x,self.y},{self._x,self._y},b[1],b[2])
			self.x, self.y = self.x + deflection[1], self.y + deflection[2]
		end
	end
	--bricks
	local edges, l = bricks:getEdges()
	for i=l, 1, -1 do
		local b = edges[i]
		if b and math.checkIntersect({self.x,self.y},{self._x,self._y},b[1],b[2]) then
			local z = math.max((self.vec[1]^2 + self.vec[2]^2)^(0.5) + .2, 18)
			local deflection = {math.deflect({b[1][1],b[1][2],b[2][1],b[2][2]},{self.x,self.y,self._x,self._y})}
			self.vec[1], self.vec[2] = z*deflection[1], z*deflection[2]
			self.x, self.y = math.getIntercept({self.x,self.y},{self._x,self._y},b[1],b[2])
			self.x, self.y = self.x + deflection[1], self.y + deflection[2]
			bricks:collided(math.floor((i-1)/4)+1)
			break
		end
	end
	for i=1, #balls do
		local b = balls[i]
		if b and b~= self and math.dist(self.x,self.y,b.x,b.y) <= 6 then
			self.vec,b.vec = b.vec,self.vec
		end
	end
	if self.y < 0 then self.y = 1; self:push(math.pi/2,-self.vec[2]*2) end
	if self.x < 0 then self.x = 0; self:push(0,-self.vec[1]*2) end
	if self.x > width then self.x = width; self:push(math.pi,self.vec[1]*2) end
	if self.y > height then self.kill = true end
end

function ball:push(r,m) self.forces[#self.forces+1] = {r,m} end

brickyard = {}
brickyard.__index = brickyard

function brickyard.make(x,y,w,h,list)
	local b = {}
	setmetatable(b, brickyard)

	b.width = w
	b.height = h
	b.rows = {}
	b.edges = {}
	for i=1,h do
		local r = {}
		for j=1,w do
			r[j] = tonumber(list:sub(((i-1)*w) + j,((i-1)*w) + j))
			local _x = x + (j-1)*24
			local _y = y + (i-1)*12
			b.edges[(i-1)*w*4 + (j-1)*4 + 1] = {{_x,_y},{_x+24,_y}}
			b.edges[(i-1)*w*4 + (j-1)*4 + 2] = {{_x+24,_y},{_x+24,_y+12}}
			b.edges[(i-1)*w*4 + (j-1)*4 + 3] = {{_x,_y+12},{_x+24,_y+12}}
			b.edges[(i-1)*w*4 + (j-1)*4 + 4] = {{_x,_y},{_x,_y+12}}
		end
		b.rows[i] = r
	end
	b.x,b.y = x,y

	return b
end

function brickyard:draw()
	love.graphics.push()
	love.graphics.translate(self.x,self.y)
	for j=1, self.height do
	for i=1, self.width do
		if self.rows[j][i] ~= 0 then
			love.graphics.rectangle("fill", (i-1)*24, (j-1)*12, 22, 10)
		end
	end
	end
	love.graphics.pop()
	love.graphics.setColor(255,0,0)
	for i=1, self.width*self.height*4 do
		if self.edges[i] then
			love.graphics.line(self.edges[i][1][1],self.edges[i][1][2],self.edges[i][2][1],self.edges[i][2][2])
		end
	end
end

function brickyard:update(dt)
end

--remove a collided brick and its walls
function brickyard:collided(x)
	self.rows[math.floor((x-1)/self.width)+1][(x-1)%self.width + 1] = 0
	x = (x-1)*4 +1
	self.edges[x] = nil
	self.edges[x+1] = nil
	self.edges[x+2] = nil
	self.edges[x+3] = nil
end

--return the table of edges and how long it should be
function brickyard:getEdges()
	return self.edges, self.width*self.height*4
end

function love.load()
	love.graphics.setBackgroundColor(0,0,0)
	balls = {}
	love.window.setMode(256,512)
	width = 256
	height = 512
	flippers = {false, false,-math.pi/16,-math.pi/16,48,48,{{64,480},{112,480},.5},{{192,480},{144,480},.5},}
	bodies = {{{0,440},{64,480},.5},{{256,440},{192,480},.5},flippers[7],flippers[8]}
	bricks = brickyard.make(24,24,8,6,"111111111111111111111111111111111111111111111111")

	launchAngle = -math.pi/2
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	for i=1, #bodies do
		love.graphics.line(bodies[i][1][1], bodies[i][1][2], bodies[i][2][1], bodies[i][2][2])
	end
	bricks:draw()
	for i=1, #balls do
		balls[i]:draw()
		love.graphics.print(i,balls[i].x+12,balls[i].y)
	end
	love.graphics.line(flippers[7][1][1],flippers[7][1][2],flippers[7][2][1],flippers[7][2][2])
	love.graphics.line(flippers[8][1][1],flippers[8][1][2],flippers[8][2][1],flippers[8][2][2])

	love.graphics.line(128,512,128 + 64*math.cos(launchAngle), 512 + 64*math.sin(launchAngle))

	love.graphics.print(#balls)
end

function love.update(dt)

	launchAngle = math.atan2(love.mouse.getY()-512, love.mouse.getX()-128)



	if love.keyboard.isDown("lshift") then
		flippers[1] = true
		flippers[3] = math.pi/3
	else
		flippers[1] = false
		flippers[3] = -math.pi/16
	end
		flippers[7][1] = {64,480}
		flippers[7][2] = {64 + flippers[5]*math.cos(flippers[3]), 480 - flippers[5]*math.sin(flippers[3])}
	if love.keyboard.isDown("rshift") then
		flippers[2] = true
		flippers[4] = math.pi/3
	else
		flippers[2] = false
		flippers[4] = -math.pi/16
	end
		flippers[8][1] = {192,480}
		flippers[8][2] = {192 - flippers[6]*math.cos(flippers[4]), 480 - flippers[6]*math.sin(flippers[4])}


	local kills = 0
	local nBalls = #balls
	for i=1, #balls do
		balls[i]:update(dt)

		if balls[i].kill then
			balls[i] = nil
			kills = kills + 1
		end
	end

	if kills > 0 then
		_balls = {}
		for i=1, nBalls do
			if balls[i] then
				_balls[#_balls+1] = balls[i]
			end
		end
		balls = _balls
	end
end

function love.keypressed(k)
	if k == ' ' then
		balls[#balls + 1] = ball.make(128,512,{launchAngle,18})
	elseif k == 'escape' then
		love.event.quit()
	end
end

function love.mousepressed(x,y,button)
	balls[#balls + 1] = ball.make(x,y,{0,0})
end