
-- Module/class for platformer enemy
-- Use this as a template to build an in-game enemy 

-- Define module
local M = {}

local composer = require( "composer" )
local playerBullets = {}

function M.new( instance )

	if not instance then error( "ERROR: Expected display object" ) end

	-- Get scene and sounds
	local scene = composer.getScene( composer.getSceneName( "current" ) )
	local sounds = scene.sounds

	-- Store map placement and hide placeholder
	instance.isVisible = false
	local parent = instance.parent
	local x, y = instance.x, instance.y

	-- Load spritesheet

    -- our character
    local sheetOptionsIdleRobot = require("assets.spritesheets.robot.robotIdle")
    local sheetIdleRobot = graphics.newImageSheet( "./assets/spritesheets/robot/robotIdle.png", sheetOptionsIdleRobot:getSheet() )

    local sheetOptionsRunRobot = require("assets.spritesheets.robot.robotRun")
    local sheetRunningRobot = graphics.newImageSheet( "./assets/spritesheets/robot/robotRun.png", sheetOptionsRunRobot:getSheet() )

    -- sequences table
    local sequence_data = {
        -- consecutive frames sequence
        {
            name = "idle",
            start = 1,
            count = 10,
            time = 800,
            loopCount = 0,
            sheet = sheetOptionsIdleRobot
        },
        {
            name = "walk",
            start = 1,
            count = 10,
            time = 1000,
            loopCount = 0,
            sheet = sheetRunningRobot
        }
    }

    instance = display.newSprite( parent, sheetIdleRobot, sequence_data )
	instance.x,instance.y = x, y
	instance:setSequence( "walk" )
	instance:play()


	-- Load spritesheet
	--local sheetData = { width = 192, height = 256, numFrames = 79, sheetContentWidth = 1920, sheetContentHeight = 2048 }
	--local sheet = graphics.newImageSheet( "scene/game/img/sprites.png", sheetData )
	--local sequenceData = {
	--	{ name = "idle", frames = { 21 } },
	--	{ name = "walk", frames = { 22, 23, 24, 25 } , time = 500, loopCount = 0 },
	--}
	--instance = display.newSprite( parent, sheet, sequenceData )
	--instance.x, instance.y = x, y
	--instance:setSequence( "walk" )
	--instance:play()

	-- Add physics
	physics.addBody( instance, "dynamic", { radius = 100, density = 3, bounce = 0, friction =  1.0 } )
	instance.isFixedRotation = true
	instance.anchorY = 0.77
	instance.angularDamping = 3
	instance.isDead = false

	-- Function to make the chracter shoot
	local function onShootButton(event)
	    -- Set sequence
	    --instance.sequence = 'shoot'
	    --instance:setSequence('shoot')
	    --instance:play()
	    --timer.performWithDelay(500, instanceThrow)
	    -- Bullets
	    local aSingleBullet = display.newImage('./assets/sprites/items/Kunai.png')
	    aSingleBullet.x = instance.x 
	    aSingleBullet.y = instance.y
	    physics.addBody(aSingleBullet, 'dynamic')
	    aSingleBullet.isBullet = true
	    aSingleBullet.isFixedRotation = true
	    aSingleBullet.gravityScale = 0
	    aSingleBullet.id = 'bullet'
	    aSingleBullet:setLinearVelocity(-1500, 0) 
	    table.insert(playerBullets, aSingleBullet)

	    return true
	end

	-- Shooting time
	timer.performWithDelay(1000, onShootButton)

	-- Bullets out of bounds
	local function checkBulletsOutBounds(event)
	-- variable for the counter
	local bulletCounter

		if #playerBullet > 0 then
			for bulletCounter = #playerBullet, 1, -1 do
				if playerBullet[bulletCounter].x > display.contentWidth + 1000 or playerBullet[bulletCounter].x > display.contentWidth - 1000  then
					playerBullet[bulletCounter]:removeSelf()
					playerBullet[bulletCounter] = nil
					table.remove(playerBullet, bulletCounter)
				end
			end
		end
	end

	-- Event listener
	Runtime:addEventListener('enterFrame', checkBulletsOutBounds)

	function instance:die()
		audio.play( sounds.sword )
		self.isFixedRotation = false
		self.isSensor = true
		self:applyLinearImpulse( 0, -200 )
		self.isDead = true
	end

	function instance:preCollision( event )
		local other = event.other
		local y1, y2 = self.y + 50, other.y - other.height/2
		-- Also skip bumping into floating platforms
		if event.contact and ( y1 > y2 ) then
			if other.floating then
				event.contact.isEnabled = false
			else
				event.contact.friction = 0.1
			end
		end
	end

	local max, direction, flip, timeout = 250, 5000, 0.133, 0
	direction = direction * ( ( instance.xScale < 0 ) and 1 or -1 )
	flip = flip * ( ( instance.xScale < 0 ) and 1 or -1 )

	local function enterFrame()

		-- Do this every frame
		local vx, vy = instance:getLinearVelocity()
		local dx = direction
		if instance.jumping then dx = dx / 4 end
		if ( dx < 0 and vx > -max ) or ( dx > 0 and vx < max ) then
			instance:applyForce( dx or 0, 0, instance.x, instance.y )
		end
		
		-- Bumped
		if math.abs( vx ) < 1 then
			timeout = timeout + 1
			if timeout > 30 then
				timeout = 0
				direction, flip = -direction, -flip
			end
		end

		-- Turn around
		instance.xScale = math.min( 1, math.max( instance.xScale + flip, -1 ) )
	end

	function instance:finalize()
		-- On remove, cleanup instance, or call directly for non-visual
		Runtime:removeEventListener( "enterFrame", enterFrame )
		instance = nil
	end

	-- Add a finalize listener (for display objects only, comment out for non-visual)
	instance:addEventListener( "finalize" )

	-- Add our enterFrame listener
	Runtime:addEventListener( "enterFrame", enterFrame )

	-- Add our collision listener
	instance:addEventListener( "preCollision" )

	-- Return instance
	instance.name = "enemy"
	instance.type = "enemy"
	return instance
end

return M
