-- Configuration vars

local layout = { 
	{ '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-'           }, 
	{ 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '['           },
	{ 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'"           },
	{ 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 'shift_right' }
 }

local colCount = #layout
local rowCount = 11

local mouseNavKey = 'escape'
local mouseNavCancelKey = 'space'
local ringSize = 30
local relativeMovePixelsHorizontal = 5
local screenBufferPixels = 20


-- Runtime vars

local mouseCircle = nil
local mouseCircleTimer = nil
local isSpaceDown = nil
local isQuickNavigated = false
 

bindings = {}
relativeBindings = {}


-- Functions

function isRightCommandOnlyFilter(keyCode, flags)  
	return keyCode == 0x36 and flags.cmd and not (flags.alt or flags.shift or flags.ctrl or flags.fn) 
end

function isLeftCommandOnlyFilter(keyCode, flags)  
	return keyCode == 0x37 and flags.cmd and not (flags.alt or flags.shift or flags.ctrl or flags.fn) 
end

function isRightOptionOnlyFilter(keyCode, flags)  
	return keyCode == 61 and flags:containExactly({'alt'}) -- flags.alt and not (flags.cmd or flags.shift or flags.ctrl or flags.fn)
end

function isRightShiftOnlyFilter(keyCode, flags)  
	return keyCode == 60 and flags:containExactly({'shift'}) -- flags.alt and not (flags.cmd or flags.shift or flags.ctrl or flags.fn)
end

function isLeftOptionOnlyFilter(keyCode, flags)  
	return keyCode == 58 and flags:containExactly({'alt'}) -- flags.alt and not (flags.cmd or flags.shift or flags.ctrl or flags.fn)
end

function getDefaultWindow() 
	local screen = hs.mouse.getCurrentScreen()
	local rect = screen:fullFrame()
	return  { 
		x = screenBufferPixels, y = screenBufferPixels, h = rect.h - 2 * screenBufferPixels, w = rect.w - 2 * screenBufferPixels } 	
end

local window = getDefaultWindow()


function listenByEventTap(keyFilter, handler)
	layoutWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, function(e)
	    local flags = e:getFlags()
	    local keyCode = e:getKeyCode()
	    print(keyCode)

	    if keyFilter(keyCode, flags) then
            handler()
	    end    
	end)
	layoutWatcher:start()
	return {
		enable = function()
			layoutWatcher:start()
		end,
		disable = function()
			layoutWatcher:stop()
		end,
		delete = function() 
			layoutWatcher:stop()
			layoutWatcher:removeSelf()
		end 
	}
end
      
function getKeyListener(key, handler)
	local specialKeys = {
		['command_left'] = isLeftCommandOnlyFilter,
		['command_right'] = isRightCommandOnlyFilter,
		['option_right'] = isRightOptionOnlyFilter,
		['option_left'] = isLeftOptionOnlyFilter,
		['shift_right'] = isRightShiftOnlyFilter
	}
	for specialKey, filter in pairs(specialKeys) do
		if specialKey == key then
			print(specialKey)
			return listenByEventTap(
				filter,
				handler
				)
		end
	end

	return hs.hotkey.bind({}, key, handler) 
end

function bind()
	if #bindings ~=0 then
		for i = 1, #bindings do
			binding = bindings[i]
			binding:enable()
		end
		return
	end

	for y = 1, colCount do
		local rowLayout = layout[y]
		-- local rowCount = #rowLayout


	    for x = 1, rowCount do
			local key = rowLayout[x]
			if (key ~= nil) then

				binding = getKeyListener(key, function() 
					if isSpaceDown ~= true then
						return 
					end

					local widthPixels = window.w
					local heightPixels = window.h


					local blockSizeX = widthPixels / (rowCount)
				 	local blockSizeY = heightPixels / (colCount)

				 	window.x = window.x + blockSizeX  * (x - 1) 
			 		window.y = window.y + blockSizeY  * (y - 1)
		 			window.w = blockSizeX
		 			window.h = blockSizeY

					local xPixels = window.x  + blockSizeX/2
					local yPixels = window.y  + blockSizeY/2

					local newPos = hs.geometry.point(xPixels, yPixels)
					hs.mouse.setAbsolutePosition(newPos)

					enableRelativeMove =  function(keyY, keyX, moveX, moveY)
						local key  = layout[keyY][keyX]
						if (key) then
							local binding = keyMoveRelative(key, moveX, moveY)
							relativeBindings[#relativeBindings+1] = binding						
						end
					end

					isQuickNavigated  = true

					circleCursor({r=1, g=0, b=0}, nil)

				end)


				bindings[#bindings+1] = binding
			end

	    end
	end
end

keyMoveRelative= function(key, moveX, moveY) 
	local isActive = false
	binding = hs.hotkey.bind({}, key, 
		function()
			isActive = true
			local timer = nil
			doMove = function()
				if isActive ~= true then
					return
				end
				mousePos = hs.mouse.getAbsolutePosition()
				hs.mouse.setAbsolutePosition(
					hs.geometry.point(mousePos.x + moveX, mousePos.y + moveY)
					)
				circleCursor()
				if isActive == true then
					timer = hs.timer.doAfter(0.010, doMove) 
				end
			end
			doMove()
		end,
		function()
			isActive = false
			if timer then
				timer.stop()
			end
		end
		)
	return binding
end

clickCurrentPosition = function() 
	local mousePos = hs.mouse.getAbsolutePosition()
	local mouseClickEvent = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, mousePos)
	mouseClickEvent:post()
	local mouseClickEventUp = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, mousePos)
	mouseClickEventUp:post()
end

hideCircleCursorIfExists = function()
	if mouseCircle then
	    mouseCircle:delete()
	    if mouseCircleTimer then
	        mouseCircleTimer:stop()
	    end
	end
end

circleCursor = function(rgb, showSeconds)
	mousePos = hs.mouse.getAbsolutePosition()
	-- Delete an existing highlight if it exists
	hideCircleCursorIfExists()
	-- Get the current co-ordinates of the mouse pointer
	-- Prepare a big red circle around the mouse pointer
	mouseCircle = hs.drawing.circle(hs.geometry.rect(mousePos.x-ringSize/2, mousePos.y-ringSize/2, ringSize, ringSize))
	mouseCircle:setStrokeColor({["red"]=rgb.r,["blue"]=rgb.b,["green"]=rgb.g,["alpha"]=1})
	mouseCircle:setFill(false)
	mouseCircle:setStrokeWidth(5)
	mouseCircle:show()	

    if showSeconds ~= nil then
 	    mouseCircleTimer = hs.timer.doAfter(showSeconds, function() mouseCircle:delete() end)
    end
end

unbind = function() 
	for i = 1, #bindings do
		binding = bindings[i]
		binding:disable()
	end
	for i = 1, #relativeBindings do
		binding = relativeBindings[i]
		binding:delete()
	end
	relativeBindings = {}
end

local mouseNavCancelKeyBinding = nil

-- Enter Hyper Mode when Spacebar is pressed
pressedSpace = function()
	print("space down")
	isSpaceDown = true 
	window = getDefaultWindow()

	bind()

	mouseNavCancelKeyBinding:enable()			
end

-- Leave Hyper Mode when Spacebar is pressed,
-- send space if no other keys are pressed.
cancelMouseNav = function()
	print("space up")
	unbind()	
	isSpaceDown = false

  	mouseNavKeyBinding:disable() -- hs seems to be triggered by his onw keyStroke, so needs to be disables before we can emit the mouseNavKeyBinding

	if isQuickNavigated ~= true then    
    	hs.eventtap.keyStroke( {}, mouseNavKey )
	end	
    mouseNavKeyBinding:enable()
    isQuickNavigated = false

    mouseNavCancelKeyBinding:disable()
    -- hideCircleCursorIfExists()
  -- end
end

handleMouseNavKeyUp = function()
	if isQuickNavigated == true then    			
		circleCursor({r=0, g=1, b=0}, 0.3)	
		clickCurrentPosition()
	end
	cancelMouseNav()
end

-- Main binding on spacebar
mouseNavKeyBinding = hs.hotkey.bind( {}, mouseNavKey, pressedSpace, handleMouseNavKeyUp )

mouseNavCancelKeyBinding = hs.hotkey.new( {}, mouseNavCancelKey, 
	function() 
		if isSpaceDown == true then
			hideCircleCursorIfExists()
			cancelMouseNav()
		end
	end, 	
	function() 
	end
	)
