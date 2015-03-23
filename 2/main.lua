--[[ Draws a dotted line ]]
function love.graphics.stippledLine( x1,y1,x2,y2,l,g )
	-- "l" and "g" are length and gap, respectively
	local ang = math.atan2((y2-y1),(x2-x1))
	local x_dist = math.cos(ang)
	local y_dist = math.sin(ang)
	for i=0, math.floor(((x2-x1)^2+(y2-y1)^2)^.5/(l+g)) do
		love.graphics.line(x1+(i*x_dist*(l+g)),y1+(i*y_dist*(l+g)),x1+(i*x_dist*(l+g))+(x_dist*l),y1+(i*y_dist*(l+g))+(y_dist*l))
	end
end
-- Checks if two line segments intersect. Line segments are given in form of ({x,y},{x,y}, {x,y},{x,y}).
function math.checkIntersect(l1p1, l1p2, l2p1, l2p2)
    local function checkDir(pt1, pt2, pt3) return math.sign(((pt2[1]-pt1[1])*(pt3[2]-pt1[2])) - ((pt3[1]-pt1[1])*(pt2[2]-pt1[2]))) end
    return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end
-- Gets the intersection 
function math.getIntercept(l1p1, l1p2, l2p1, l2p2)
	local m1 = (l1p2[2]-l1p1[2])/(l1p2[1]-l1p1[1])
	local m2 = (l2p2[2]-l2p1[2])/(l2p2[1]-l2p1[1])
	if not (m1 and m2) or m1 == m2 then
		return 0,0
	end
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
-------------------------------------------------
-------------------------------------------------

function love.load()

	love.window.setMode(256,512)

	wall = {256,128,0,192,}
	vector = {nil,nil,nil,nil}
	_vector = {nil,nil,nil,nil}
	phi = math.atan3(wall[4],wall[2],wall[3],wall[1])
	theta = 0
end

function love.draw()
	love.graphics.setColor(192,192,192)
	love.graphics.setLineWidth(2)
	love.graphics.line(unpack(wall))
	
	if vector[1] then
		love.graphics.setColor(255,255,255)
		love.graphics.setLineWidth(1)
		love.graphics.line(unpack(vector))

		love.graphics.stippledLine(vector[1],vector[2],_vector[1],_vector[2],4,4)
		love.graphics.setColor(255,0,0)
		love.graphics.stippledLine(_vector[1],_vector[2],_vector[3],_vector[4],4,4)
	end


end

function love.update(dt)
	if love.mouse.isDown('l') then
		vector[3], vector[4] = 
			love.mouse.getPosition()

		theta = math.atan3(vector[4], vector[2], vector[3], vector[1])
		if vector[4] < vector[2] then 
			theta = theta - 2*phi
		else
			theta = theta - 2*phi - math.pi
		end

		local tx, ty = math.getIntercept({vector[1],vector[2]},
										 {vector[3],vector[4]},
										 {wall[1],wall[2]},
										 {wall[3],wall[4]})

		_vector[1], _vector[2] = tx, ty
		_vector[3] = _vector[1] + 64*math.cos(theta)
		_vector[4] = _vector[2] - 64*math.sin(theta)
		-- print(_vector[1], _vector[2], _vector[3], _vector[4])
	else
		vector[3], vector[4] = nil, nil
		vector[1], vector[2] = nil, nil
	end
end

function love.mousepressed(x,y,button)
	vector[1], vector[2] = x, y
end