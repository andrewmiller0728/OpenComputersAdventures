-- [[ PLANT FARMING ROBOT ]]--
-- Goals:
--      - Sowing seeds in tilled soil
--      - Maintaining grounds
--      - Harvest at appropriate intervals
--      - Organize storage of resouces and products
--      - Have a personal UX
--      - Keep track of production rate


-- [[ MAIN ]] --

local function main()
    local run = true
    -- Central loop, think like arduino code
    while (run) do
        -- Based on if...else switch between states
    end
end


-- [[ STATES ]] --

local function resting()
    -- wait for future input
end

local function charging()
    -- Return to charger
    -- Wait for full charge
end

local function tilling()
    -- till all designated blocks
    -- do not till blocks which are already tilled
end

local function sowing()
    -- sow seeds in all designated, tilled, unoccupied blocks
    -- return unused seeds to storage
end

local function harvesting()
    -- Harvest all crops at appropriate intervals
    -- Return harvested crops and seeds to storage
    -- BONUS: havest only mature crops
end


-- [[ COMMON TASKS ]] --

local function replaceTool(tool)
    -- Discard current tool
    -- Retrieve new tool from storage
    -- BONUS: if no tools in storage, make one
end