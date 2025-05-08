WATER_SHED_PATH = "C:\\Users\\jana_\\OneDrive - UW\\ewb-rainwater-game"

TIME_OUT_TIME = 90
timeout_timer = 0
common_font = love.graphics.newFont(14)


PERCENT_TARGET_FOOTPRINT = 0.75
CHOICE_BOX_H = 100


BACKGROUND_TRANSPARENCY = 50
MAX_TIME_CURR_CHOICES = 5


-- UTILITY FUNCTIONS

function key_of(values, value)
  local index = {}
  for k, v in pairs(values) do
     index[v]=k
  end
  return index[value]
end

function printx(text)
  love.window.showMessageBox("Message", text, "info", true)
end

function file_exists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function star(cx, cy, spikes, startAngle, outerRadius, innerRadius)
  rot = startAngle;
  step = math.pi / spikes;
  
  x = cx
  y = cy
  
  vertices = {}

  table.insert(vertices, cx)
  table.insert(vertices, cy - outerRadius)
    
  for i = 0, spikes do
    x = cx + math.cos(rot) * outerRadius;
    y = cy + math.sin(rot) * outerRadius;
    table.insert(vertices, x)
    table.insert(vertices, y)
    rot = rot + step

    x = cx + math.cos(rot) * innerRadius;
    y = cy + math.sin(rot) * innerRadius;
    table.insert(vertices, x)
    table.insert(vertices, y)
    rot = rot + step
  end
  table.insert(vertices, cx)
  table.insert(vertices, cy-outerRadius)
  
  return vertices
end

function from_csv(s)
  s = s .. ','        -- ending comma
  local t = {}        -- table to collect fields
  local fieldstart = 1
  repeat
    -- next field is quoted? (start with `"'?)
    if string.find(s, '^"', fieldstart) then
      local a, c
      local i  = fieldstart
      repeat
        -- find closing quote
        a, i, c = string.find(s, '"("?)', i+1)
      until c ~= '"'    -- quote not followed by quote?
      if not i then error('unmatched "') end
      local f = string.sub(s, fieldstart+1, i-1)
      table.insert(t, (string.gsub(f, '""', '"')))
      fieldstart = string.find(s, ',', i) + 1
    else                -- unquoted; find next comma
      local nexti = string.find(s, ',', fieldstart)
      table.insert(t, string.sub(s, fieldstart, nexti-1))
      fieldstart = nexti + 1
    end
  until fieldstart > string.len(s)
  return t
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

function table.val_to_str ( v )
  if "string" == type( v ) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type( v ) and table.tostring( v ) or
      tostring( v )
  end
end

function table.key_to_str ( k )
  if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
    return k
  else
    return "[" .. table.val_to_str( k ) .. "]"
  end
end

function table.tostring(tbl)
  local result, done = {}, {}
  for k, v in ipairs( tbl ) do
    table.insert( result, table.val_to_str( v ) )
    done[ k ] = true
  end
  for k, v in pairs( tbl ) do
    if not done[ k ] then
      table.insert( result,
        table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

function mouse_over(x, y, w, h)
  return love.mouse.getX() >= x and love.mouse.getX() <= x + w and love.mouse.getY() >= y and love.mouse.getY() <= y + h
end

-- VARIABLES FOR GAME
curr_page = "main" -- main -> phase_a_intro -> phase_a -> footprint -> phase_b -> results -> pledges | main
width, height = 0, 0
f_c = 0
is_mouse_clicked = false
mouse = {
  x = 0,
  y = 0,
}

-- fonts
regular_font = love.graphics.newFont(10)
monospace_font = love.graphics.newFont(10)

-- transitions
transition = {
  to = "main",
  y = 0,
  to_y = 0,
  page_responsive_timer = 2 -- timer for page to become responsive
}
next_screen_timer = 0

COLOR_VALUE_FACTOR = 1

player = {
  curr_choice_timer = MAX_TIME_CURR_CHOICES,
  curr_choice_index = 1,
  num_choices_left = 6,
  curr_selected_choices = {false, false, false, false, false, false},
  curr_selected_choices_f = {20, 20, 20, 20, 20, 20},
  curr_selected_choices_f_to = {20, 20, 20, 20, 20, 20},
  target_footprint = 0,
  achieved_footprint = 0,
  phase_a_choice_indices = {},
}
footprint_bar_x = 0

CHOICES = {}

function load_water_shed()
  pledge_index = 0

  player = {
    curr_choice_timer = MAX_TIME_CURR_CHOICES,
    curr_choice_index = 1,
    num_choices_left = 6,
    curr_selected_choices = {false, false, false, false, false, false},
    curr_selected_choices_f = {20, 20, 20, 20, 20, 20},
    curr_selected_choices_f_to = {20, 20, 20, 20, 20, 20},
    target_footprint = 0,
    achieved_footprint = 0,
    phase_a_choice_indices = {},
  }
  footprint_bar_x = 0

  CHOICES = {}

  CHOICES = {}
  -- for line in io.lines("/sdcard/lovegame/data/choices.csv") do
  for line in io.lines(WATER_SHED_PATH .. "data/choices.csv") do
    parsed_csv = from_csv(line)
    num_cols_on_line = 0
    for i, col in pairs(parsed_csv) do
      if col ~= "" and col ~= nil and #col > 0 and col:match("%S") ~= nil then
        num_cols_on_line = num_cols_on_line + 1
      end
    end

    NEW_CHOICE = {
      text = parsed_csv[1],
      choices = {unpack(parsed_csv, 3, 2 + ((num_cols_on_line-2) / 2))},
      choice_footprints = {unpack(parsed_csv, 2 + ((num_cols_on_line-2) / 2) + 1, num_cols_on_line)},
      bg_image = parsed_csv[2]
    }

    table.insert(CHOICES, NEW_CHOICE)
  end

  footprint_bar_x = 0

  player.num_choices_left = 6
  player.curr_choice_timer = MAX_TIME_CURR_CHOICES
  player.curr_choice_index = love.math.random(math.ceil((6 - player.num_choices_left) * #CHOICES/6) + 1, math.floor((6 - player.num_choices_left + 1) * #CHOICES/6) - 1)

  player.curr_selected_choices = {}
  for index, choice in pairs(CHOICES[player.curr_choice_index].choices) do
    player.curr_selected_choices[index] = false
    player.curr_selected_choices_f[index] = 20
    player.curr_selected_choices_f_to[index] = 20
  end

  player.target_footprint = 0
  player.achieved_footprint = 0
  player.phase_a_choice_indices = {}

  player.phase_a_choices = {}
  player.phase_a_choice_footprints = {}

  factoid_data = {
    {"It takes 700 gallons of water to make one cotton t-shirt", "Shop secondhand and thrift stores to reduce your water footprint!"},
    {"Per ton, animal products require more water to produce than crops", "Routinely eat plant-based meals to reduce your water footprint!"},
    {"It takes 1000 gallons of water to produce a gallon of milk", "Eating low on the food chain can help reduce your water impact"},
    {"60-70% of our water footprint is from the foods we eat", "Eating low on the food chain can help reduce your water impact"},
    {"It takes a gallon of water to produce a gallon of gasoline", "Finding ways to cut fossil fuel use also saves water!"},
    {"Plastics manufacturing takes huge amounts of water and energy", "Find alternatives to single-use plastics whenever possible"},
    {"It takes 1-1/2 gallons of water to make a single bottle of water", "Cut out plastic bottles for a huge dent in your water footprint!"},
    {"Only 2.5% of the world's water is freshwater", "Individuals, business, and government can all help conserve!"},
    {"It takes a gallon of water to produce a single sheet of paper", "Cutting down on paper products helps reduce water footprints"},
    {"Producing electricity and refining gasoline are huge \"water hogs\"", "When you conserve energy, you also conserve water!"},
    {"Enormous amounts of water go into producing clothing", "Shop secondhand and thrift stores to reduce your water footprint!"},
    {"Water used to make goods can end up polluting local ecosystems", "Buying used or refurbished items have zero water impact!"}
  }
  factoid_to_show = factoid_data[love.math.random(#factoid_data)]

  next_screen_timer = 0
end

RANDOM_GRAPHICS = {}

-- LOAD GAME
function love.load()
  IMAGE_PATH = WATER_SHED_PATH .. "res/"

  common_font = love.graphics.newFont("res/AvenirLTStd-Heavy.otf", 55)

  love.window.setTitle("Water Shed")

  love.window.setFullscreen(true)
  
  width = love.graphics.getWidth()
  height = love.graphics.getHeight()
  
  regular_font = love.graphics.newFont("res/elite_font.ttf", 50) -- 60
  smallest_font = love.graphics.newFont("res/elite_font.ttf", 25) -- 35
  small_font = love.graphics.newFont("res/elite_font.ttf", 30) -- 45
  title_font = love.graphics.newFont("res/elite_font.ttf", 84) -- 84

  RANDOM_GRAPHICS = {
    title = love.graphics.newImage("res/random/title.png")
  }

  BACKGROUND_GRAPHIC_NAMES = {
  }
  BACKGROUND_GRAPHICS = {
  }
  background_image_file_name_number = 1
  -- while file_exists("/sdcard/lovegame/res/background/" .. background_image_file_name_number .. ".png") do
  while file_exists(IMAGE_PATH .. "background/" .. background_image_file_name_number .. ".png") do
    table.insert(BACKGROUND_GRAPHIC_NAMES, background_image_file_name_number .. ".png")
    table.insert(BACKGROUND_GRAPHICS, love.graphics.newImage("res/background/" .. background_image_file_name_number .. ".png"))
    background_image_file_name_number = background_image_file_name_number + 1
  end

  load_water_shed()
end

-- UPDATE

function love.update(dt)
  if curr_page == "main" then
    if is_mouse_clicked then
      load_water_shed()

      pledges_file = io.open(WATER_SHED_PATH .. "data/log.txt", "a")
      io.output(pledges_file)
      io.write(os.date("%c") .. " tap to play button pressed", "\n")
      io.close(pledges_file)
  
      -- transition to sorting
      next_screen_timer = 0
      transition_to("phase_a_intro")
    end
    
  elseif curr_page == "phase_a_intro" then
    if is_mouse_clicked then
      transition_to("phase_a")
    end
  elseif curr_page == "phase_a" then
    -- update selected choices
    num_choice_sets = math.ceil(#curr_choice_choices/3)
    for index, choice in pairs(curr_choice_choices) do
      if index % 3 == 1 then
        curr_choice_set_index = math.ceil(index/3)

        -- display button
        love.graphics.setColor(40/255, 40/255, 40/255, 20/255)
        if is_mouse_clicked and mouse_over(10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = true
          player.curr_selected_choices[index + 1] = false
          player.curr_selected_choices[index + 2] = false
        end
        if is_mouse_clicked and mouse_over(10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = false
          player.curr_selected_choices[index + 1] = true
          player.curr_selected_choices[index + 2] = false
        end
        if is_mouse_clicked and mouse_over(10 + (width - 40)/3 + 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = false
          player.curr_selected_choices[index + 1] = false
          player.curr_selected_choices[index + 2] = true
        end
      end
    end

    -- update timer
    if f_c % 60 == 0 then
      player.curr_choice_timer = player.curr_choice_timer - 1
    end

    -- move to next choice
    if player.curr_choice_timer < 0 then
      -- record index of current choice
      table.insert(player.phase_a_choice_indices, player.curr_choice_index)

      -- update number of choices left
      player.num_choices_left = player.num_choices_left - 1

      -- set choices to random default if player did not choose
      for index, choice in pairs(player.curr_selected_choices) do
        if index % 3 == 1 then
          if player.curr_selected_choices[index] == false and player.curr_selected_choices[index + 1] == false and player.curr_selected_choices[index + 2] == false then
            player.curr_selected_choices[love.math.random(index, index + 2)] = true
          end
        end
      end

      for index, choice in pairs(player.curr_selected_choices) do
        if choice and CHOICES[player.curr_choice_index].choice_footprints[index] ~= nil then
          table.insert(player.phase_a_choices, CHOICES[player.curr_choice_index].choices[index])
          table.insert(player.phase_a_choice_footprints, CHOICES[player.curr_choice_index].choice_footprints[index])
          -- player.achieved_footprint = player.achieved_footprint + CHOICES[player.curr_choice_index].choice_footprints[index]
        end
      end

      -- update footprint
      for index, choice in pairs(player.curr_selected_choices) do
        if choice then
          player.target_footprint = player.target_footprint + CHOICES[player.curr_choice_index].choice_footprints[index]
        end
      end

      if player.num_choices_left <= 0 then
        transition_to("phase_a_results")
        player.curr_choice_timer = MAX_TIME_CURR_CHOICES
        player.curr_choice_index = 1
        player.num_choices_left = 6
      else
        transition_to("phase_a")
        player.curr_choice_timer = MAX_TIME_CURR_CHOICES
        new_curr_choice_index = player.curr_choice_index
        is_new_curr_choice_index_valid = false
        while not is_new_curr_choice_index_valid do
          new_curr_choice_index = love.math.random(math.ceil((6 - player.num_choices_left) * #CHOICES/6) + 1, math.floor((6 - player.num_choices_left + 1) * #CHOICES/6) - 1)
          is_new_curr_choice_index_valid = new_curr_choice_index ~= player.curr_choice_index
          for j, phase_a_choice_index in pairs(player.phase_a_choice_indices) do
            if new_curr_choice_index == phase_a_choice_index then
              is_new_curr_choice_index_valid = false
            end
          end
        end
        player.curr_choice_index = new_curr_choice_index
      end

      player.curr_selected_choices = {}
      for index, choice in pairs(CHOICES[player.curr_choice_index].choices) do
        player.curr_selected_choices[index] = false
        player.curr_selected_choices_f[index] = 20
        player.curr_selected_choices_f_to[index] = 20
      end
    end
  elseif curr_page == "phase_a_results" then
    if is_mouse_clicked then
      transition_to("phase_b")
      player.curr_choice_index = player.phase_a_choice_indices[1]
    end
  elseif curr_page == "phase_b" then
    
    -- update selected choices
    num_choice_sets = math.ceil(#curr_choice_choices/3)
    for index, choice in pairs(curr_choice_choices) do
      if index % 3 == 1 then
        curr_choice_set_index = math.ceil(index/3)

        -- display button
        love.graphics.setColor(40/255, 40/255, 40/255, 20/255)
        if is_mouse_clicked and mouse_over(10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = true
          player.curr_selected_choices[index + 1] = false
          player.curr_selected_choices[index + 2] = false
        end
        if is_mouse_clicked and mouse_over(10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = false
          player.curr_selected_choices[index + 1] = true
          player.curr_selected_choices[index + 2] = false
        end
        if is_mouse_clicked and mouse_over(10 + (width - 40)/3 + 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H) then
          player.curr_selected_choices[index] = false
          player.curr_selected_choices[index + 1] = false
          player.curr_selected_choices[index + 2] = true
        end
      end
    end

    -- update timer
    if f_c % 60 == 0 then
      player.curr_choice_timer = player.curr_choice_timer - 1
    end

    -- move to next choice
    if player.curr_choice_timer < 0 then
      -- set choices to random default if player did not choose
      for index, choice in pairs(player.curr_selected_choices) do
        if index % 3 == 1 then
          if player.curr_selected_choices[index] == false and player.curr_selected_choices[index + 1] == false and player.curr_selected_choices[index + 2] == false then
            player.curr_selected_choices[love.math.random(index, index + 2)] = true
          end
        end
      end
      -- update footprint
      for index, choice in pairs(player.curr_selected_choices) do
        if choice and CHOICES[player.curr_choice_index].choice_footprints[index] ~= nil then
          table.insert(player.phase_a_choices, CHOICES[player.curr_choice_index].choices[index])
          table.insert(player.phase_a_choice_footprints, CHOICES[player.curr_choice_index].choice_footprints[index])
          player.achieved_footprint = player.achieved_footprint + CHOICES[player.curr_choice_index].choice_footprints[index]
        end
      end

      player.num_choices_left = player.num_choices_left - 1

      if player.num_choices_left <= 0 then
        transition_to("results")
        player.curr_choice_timer = MAX_TIME_CURR_CHOICES
        player.curr_choice_index = 1
        player.num_choices_left = 6
      else
        transition_to("phase_b")
        player.curr_choice_timer = MAX_TIME_CURR_CHOICES
        -- update number of choices left
        -- update current choice index
        player.curr_choice_index = player.phase_a_choice_indices[6 - player.num_choices_left + 1]
      end

      player.curr_selected_choices = {}
      for index, choice in pairs(CHOICES[player.curr_choice_index].choices) do
        player.curr_selected_choices[index] = false
        player.curr_selected_choices_f[index] = 20
        player.curr_selected_choices_f_to[index] = 20
      end
    end
  elseif curr_page == "results" then
    if is_mouse_clicked then
      if mouse.y > height/2 + 25*7 then
        if mouse.x < width / 2 then
          transition_to("main")
          transition_to("main")
          pledges_file = io.open(WATER_SHED_PATH .. "data/log.txt", "a")
          io.output(pledges_file)
          io.write(os.date("%c") .. " play again button pressed", "\n")
          io.close(pledges_file)
        elseif mouse.y > width / 2 then
          transition_to("acknowledgements")
        end
      end
    end
  elseif curr_page == "acknowledgements" then
    if is_mouse_clicked then
      transition_to("main")
    end
  end
  
  -- handle transitions
  transition.y = transition.y + (transition.to_y - transition.y) / 3
  if transition.y > transition.to_y - 10 then
    curr_page = transition.to
    transition.to_y = 0
  end
  
  -- update page responsive timer
  if f_c % 60 == 0 then
    transition.page_responsive_timer = transition.page_responsive_timer - 1
  end
  
  -- handle end of frame update
  f_c = f_c + 1
  is_mouse_clicked = false

  if f_c % 60 == 0 then
    timeout_timer = timeout_timer + 1
  end
  if timeout_timer > TIME_OUT_TIME then
      transition_to("main")
      timeout_timer = 0
  end
end

-- DRAW

function love.draw(dt)  
  -- menu page
  if curr_page == "main" then
    love.graphics.setBackgroundColor(0/255, 193/255, 227/255)
    --love.graphics.setBackgroundColor(158/255, 193/255, 227/255)

    love.graphics.setColor(255, 255, 255)
    --love.graphics.setColor(50/255, 50/255, 50/255, 100/255)
    love.graphics.draw(RANDOM_GRAPHICS["title"], width/2 - (3059*0.6)/2, height/2 - (1890*0.6)/2, 0, 0.6)

    love.graphics.setFont(smallest_font)
    love.graphics.setColor(0, 0, 0, 80)
    --love.graphics.setColor(50/255, 50/255, 50/255)
    
  elseif curr_page == "phase_a_intro" then
    -- love.graphics.setBackgroundColor(158, 193, 227)
    love.graphics.setBackgroundColor(158/255, 193/255, 227/255)

    -- love.graphics.setColor(40, 40, 40)
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(regular_font)
    love.graphics.print("You'll have 50 seconds to make 6 choices", width/2 - regular_font:getWidth("You will have 50 seconds to make 6 choices")/2, height/2 - regular_font:getHeight() - 100)
    love.graphics.print("that impact your weekly water footprint.", width/2 - regular_font:getWidth("that impact your weekly water footprint.")/2, height/2 - regular_font:getHeight())
    love.graphics.print("Choose what fits you best!", width/2 - regular_font:getWidth("Choose what fits you best!")/2, height/2 - regular_font:getHeight() + 100)

    -- print alert
    -- love.graphics.setColor(65, 70, 75, 170)
    love.graphics.setColor(65/255, 70/255, 75/255, 170/255)
    love.graphics.setFont(regular_font)
    love.graphics.print("tap to get started", width/2 - regular_font:getWidth("tap to get started")/2, height - regular_font:getHeight() - 100)
  elseif curr_page == "phase_a" then
    -- love.graphics.setBackgroundColor(158, 193, 227)
    love.graphics.setBackgroundColor(158/255, 193/255, 227/255)

    -- love.graphics.setColor(255, 255, 255, BACKGROUND_TRANSPARENCY)
    love.graphics.setColor(1, 1, 1, BACKGROUND_TRANSPARENCY/255)
    -- love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.draw(BACKGROUND_GRAPHICS[key_of(BACKGROUND_GRAPHIC_NAMES, CHOICES[player.curr_choice_index].bg_image)], 0, 0, 0, width/3059, height/1890)

    -- print current choice
    if player.num_choices_left >= 0 then
      curr_choice_text = CHOICES[player.curr_choice_index].text
      curr_choice_choices = CHOICES[player.curr_choice_index].choices

      -- print progress
      -- love.graphics.setColor(40, 40, 40, 50)
      -- love.graphics.ellipse("fill", 200, 200, 100, 100)
      -- love.graphics.setColor(40, 40, 40)
      love.graphics.setColor(40/255, 40/255, 40/255, 50/255)
      love.graphics.ellipse("fill", 200/255, 200/255, 100/255, 100/255)
      love.graphics.setColor(40/255, 40/255, 40/255)
      love.graphics.setFont(regular_font)
      love.graphics.print((6 - player.num_choices_left + 1) .. "/" .. 6, 200-regular_font:getWidth((6 - player.num_choices_left + 1) .. "/" .. 6)/2, 200-regular_font:getHeight()/2)

      -- print choices
      num_choice_sets = math.ceil(#curr_choice_choices/3)
      selected_choice_texts = {}
      for index, choice in pairs(curr_choice_choices) do
        if index % 3 == 1 then
          curr_choice_set_index = math.ceil(index/3)

          -- update selected choice texts
          if player.curr_selected_choices[index] then
            table.insert(selected_choice_texts, curr_choice_choices[index])
          elseif player.curr_selected_choices[index + 1] then
            table.insert(selected_choice_texts, curr_choice_choices[index + 1])
          elseif player.curr_selected_choices[index + 2] then
            table.insert(selected_choice_texts, curr_choice_choices[index + 2])
          else
            table.insert(selected_choice_texts, "___")
          end

          -- display button
          player.curr_selected_choices_f[index] = player.curr_selected_choices_f[index] + (player.curr_selected_choices_f_to[index] - player.curr_selected_choices_f[index])/3
          player.curr_selected_choices_f[index + 1] = player.curr_selected_choices_f[index + 1] + (player.curr_selected_choices_f_to[index + 1] - player.curr_selected_choices_f[index + 1])/3
          player.curr_selected_choices_f[index + 2] = player.curr_selected_choices_f[index + 2] + (player.curr_selected_choices_f_to[index + 2] - player.curr_selected_choices_f[index + 2])/3
          UNSELECTED_CHOICE_F = 30
          SELECTED_CHOICE_F = 100
          if player.curr_selected_choices[index] then
            player.curr_selected_choices_f_to[index] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index]/255)
          love.graphics.rectangle("fill", 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)
          if player.curr_selected_choices[index + 1] then
            player.curr_selected_choices_f_to[index + 1] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index + 1] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index + 1]/255)
          love.graphics.rectangle("fill", 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)
          if player.curr_selected_choices[index + 2] then
            player.curr_selected_choices_f_to[index + 2] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index + 2] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index + 2]/255)
          love.graphics.rectangle("fill", 10 + (width - 40)/3 + 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)

          -- print text
          love.graphics.setColor(40/255, 40/255, 40/255)
          love.graphics.setFont(small_font)
          love.graphics.print(curr_choice_choices[index], 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
          love.graphics.print(curr_choice_choices[index + 1], 10 + (width - 40)/3 + 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index + 1])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
          love.graphics.print(curr_choice_choices[index + 2], 10 + (width - 40)/3 + 10 + (width - 40)/3 + 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index + 2])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
        end
      end

      -- print choice text
      love.graphics.setColor(40/255, 40/255, 40/255)
      love.graphics.setFont(regular_font)
      curr_choice_text_to_print = curr_choice_text
      for choice_set_index = 1, num_choice_sets do
        curr_choice_text_to_print = string.gsub(curr_choice_text_to_print, "{}", selected_choice_texts[choice_set_index], 1)
      end
      love.graphics.printf(curr_choice_text_to_print, 150, height/2 - regular_font:getHeight()/2, width - 300, "center")

      -- show timer
      love.graphics.setColor(40/255, 40/255, 40/255, 25/255)
      love.graphics.ellipse("fill", width - 200, 200, 100, 100)
      love.graphics.setColor(40/255, 40/255, 40/255, 25/255)
      love.graphics.arc("fill", width - 200, 200, 100, -math.pi/2, -math.pi/2 + (2*math.pi) * (player.curr_choice_timer+1-((f_c-1)%60)/60)/MAX_TIME_CURR_CHOICES)
      love.graphics.setFont(regular_font)
      love.graphics.setColor(40/255, 40/255, 40/255)
      love.graphics.print(player.curr_choice_timer .. " s", width - 200 - regular_font:getWidth(player.curr_choice_timer .. " s")/2, 200-regular_font:getHeight()/2)
    end
  elseif curr_page == "phase_a_results" then
    love.graphics.setBackgroundColor(158, 193, 227)

    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(regular_font)
    love.graphics.print("Your total water footprint was " .. player.target_footprint .. " gallons", width/2 - regular_font:getWidth("Your total water footprint was " .. player.target_footprint .. " gallons")/2, 150)
    love.graphics.print("Can you reduce your water footprint to " .. math.ceil(player.target_footprint * PERCENT_TARGET_FOOTPRINT) .. " gallons?", width/2 - regular_font:getWidth("Can you reduce your water footprint to " .. math.ceil(player.target_footprint * PERCENT_TARGET_FOOTPRINT) .. " gallons?")/2, 200)


    top_choices = {"", "", ""}
    top_choice_water_footprints = {0, 0, 0}
    for i, footprint in pairs(player.phase_a_choice_footprints) do
      if tonumber(footprint) > top_choice_water_footprints[1] then
        table.insert(top_choices, 1, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 1, tonumber(footprint))
      elseif tonumber(footprint) > top_choice_water_footprints[2] then
        table.insert(top_choices, 2, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 2, tonumber(footprint))
      elseif tonumber(footprint) > top_choice_water_footprints[3] then
        table.insert(top_choices, 3, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 3, tonumber(footprint))
      end
    end
    love.graphics.printf("Your biggest water footprint contributors were \"" .. top_choices[1] .. "\", \"" .. top_choices[2] .. "\", \"" .. top_choices[3] .. "\".", 150, 450, width - 300, "center")

    -- print alert
    love.graphics.setColor(65/255, 70/255, 75/255, 170/255)
    love.graphics.setFont(regular_font)
    love.graphics.print("tap to accept challenge", width/2 - regular_font:getWidth("tap to accept challenge")/2, height - regular_font:getHeight() - 80)--100)
  elseif curr_page == "phase_b" then
    love.graphics.setBackgroundColor(158/255, 193/255, 227/255)

    love.graphics.setColor(255/255, 255/255, 255/255, BACKGROUND_TRANSPARENCY/255)
    love.graphics.draw(BACKGROUND_GRAPHICS[key_of(BACKGROUND_GRAPHIC_NAMES, CHOICES[player.curr_choice_index].bg_image)], 0, 0, 0, width/3059, height/1890)

    love.graphics.setColor(40/255, 40/255, 40/255, 15/255)
    love.graphics.rectangle("fill", 0, 0, width, 80)
    love.graphics.setColor(40/255, 40/255, 40/255, 45/255)
    footprint_bar_x = footprint_bar_x + (width*player.achieved_footprint/(player.target_footprint) - footprint_bar_x) / 20
    love.graphics.rectangle("fill", 0, 0, footprint_bar_x, 80)
    love.graphics.rectangle("fill", width*PERCENT_TARGET_FOOTPRINT - 40, 0, 20, 80)
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(smallest_font)
    love.graphics.print("goal : not more than " .. math.floor(player.target_footprint*PERCENT_TARGET_FOOTPRINT), width*PERCENT_TARGET_FOOTPRINT + 20, 40-smallest_font:getHeight()/2)

    -- print progress
    love.graphics.setColor(40/255, 40/255, 40/255, 50/255)
    love.graphics.ellipse("fill", 200, 200, 100, 100)
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(regular_font)
    love.graphics.print((6 - player.num_choices_left + 1) .. "/" .. 6, 200-regular_font:getWidth((6 - player.num_choices_left + 1) .. "/" .. 6)/2, 200-regular_font:getHeight()/2)

    -- print choices
    if player.num_choices_left >= 0 then
      curr_choice_text = CHOICES[player.curr_choice_index].text
      curr_choice_choices = CHOICES[player.curr_choice_index].choices
      num_choice_sets = math.ceil(#curr_choice_choices/3)
      selected_choice_texts = {}
      for index, choice in pairs(curr_choice_choices) do
        if index % 3 == 1 then
          curr_choice_set_index = math.ceil(index/3)

          -- update selected choice texts
          if player.curr_selected_choices[index] then
            table.insert(selected_choice_texts, curr_choice_choices[index])
          elseif player.curr_selected_choices[index + 1] then
            table.insert(selected_choice_texts, curr_choice_choices[index + 1])
          elseif player.curr_selected_choices[index + 2] then
            table.insert(selected_choice_texts, curr_choice_choices[index + 2])
          else
            table.insert(selected_choice_texts, "___")
          end

          -- display button
          player.curr_selected_choices_f[index] = player.curr_selected_choices_f[index] + (player.curr_selected_choices_f_to[index] - player.curr_selected_choices_f[index])/3
          player.curr_selected_choices_f[index + 1] = player.curr_selected_choices_f[index + 1] + (player.curr_selected_choices_f_to[index + 1] - player.curr_selected_choices_f[index + 1])/3
          player.curr_selected_choices_f[index + 2] = player.curr_selected_choices_f[index + 2] + (player.curr_selected_choices_f_to[index + 2] - player.curr_selected_choices_f[index + 2])/3
          UNSELECTED_CHOICE_F = 30
          SELECTED_CHOICE_F = 100
          if player.curr_selected_choices[index] then
            player.curr_selected_choices_f_to[index] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index]/255)
          love.graphics.rectangle("fill", 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)
          if player.curr_selected_choices[index + 1] then
            player.curr_selected_choices_f_to[index + 1] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index + 1] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index + 1]/255)
          love.graphics.rectangle("fill", 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)
          if player.curr_selected_choices[index + 2] then
            player.curr_selected_choices_f_to[index + 2] = SELECTED_CHOICE_F
          else
            player.curr_selected_choices_f_to[index + 2] = UNSELECTED_CHOICE_F
          end
          love.graphics.setColor(40/255, 40/255, 40/255, player.curr_selected_choices_f[index + 2]/255)
          love.graphics.rectangle("fill", 10 + (width - 40)/3 + 10 + (width - 40)/3 + 10, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1), (width - 40)/3, CHOICE_BOX_H)

          -- print text
          love.graphics.setColor(40/255, 40/255, 40/255)
          love.graphics.setFont(small_font)
          love.graphics.print(curr_choice_choices[index], 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
          love.graphics.print(curr_choice_choices[index + 1], 10 + (width - 40)/3 + 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index + 1])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
          love.graphics.print(curr_choice_choices[index + 2], 10 + (width - 40)/3 + 10 + (width - 40)/3 + 10 + ((width - 40)/3)/2 - small_font:getWidth(curr_choice_choices[index + 2])/2, height - (CHOICE_BOX_H + 10)*(num_choice_sets - curr_choice_set_index + 1) + CHOICE_BOX_H/2 - small_font:getHeight()/2)
        end
      end
    end

    -- print text
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(regular_font)
    curr_choice_text_to_print = curr_choice_text
    for choice_set_index = 1, num_choice_sets do
      curr_choice_text_to_print = string.gsub(curr_choice_text_to_print, "{}", selected_choice_texts[choice_set_index], 1)
    end
    love.graphics.printf(curr_choice_text_to_print, 150, height/2 - regular_font:getHeight()/2, width - 300, "center")

    -- show timer
    love.graphics.setColor(40/255, 40/255, 40/255, 25/255)
    love.graphics.ellipse("fill", width - 200, 200, 100, 100)
    love.graphics.setColor(40/255, 40/255, 40/255, 25/255)
    love.graphics.arc("fill", width - 200, 200, 100, -math.pi/2, -math.pi/2 + (2*math.pi) * (player.curr_choice_timer+1-((f_c-1)%60)/60)/MAX_TIME_CURR_CHOICES)
    love.graphics.setFont(regular_font)
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.print(player.curr_choice_timer, width - 200 - regular_font:getWidth(player.curr_choice_timer)/2, 200-regular_font:getHeight()/2)
  elseif curr_page == "results" then
    love.graphics.setBackgroundColor(158, 193, 227)

    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(regular_font)
    if player.achieved_footprint < math.floor(player.target_footprint * PERCENT_TARGET_FOOTPRINT) then
      love.graphics.printf("Congratulations! You beat your target water footprint of " .. math.floor(player.target_footprint * PERCENT_TARGET_FOOTPRINT) .. " with " .. player.achieved_footprint .. " gallons.", 150, 200, width - 300, "center")
    else
      love.graphics.printf("Oh no! You failed to beat your target water footprint of " .. math.floor(player.target_footprint * PERCENT_TARGET_FOOTPRINT) .. "; instead you had " .. player.achieved_footprint .. " gallons.", 150, 200, width - 300, "center")
    end

    top_choices = {"", "", ""}
    top_choice_water_footprints = {0, 0, 0}
    for i, footprint in pairs(player.phase_a_choice_footprints) do
      if tonumber(footprint) > top_choice_water_footprints[1] then
        table.insert(top_choices, 1, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 1, tonumber(footprint))
      elseif tonumber(footprint) > top_choice_water_footprints[2] then
        table.insert(top_choices, 2, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 2, tonumber(footprint))
      elseif tonumber(footprint) > top_choice_water_footprints[3] then
        table.insert(top_choices, 3, player.phase_a_choices[i])
        table.insert(top_choice_water_footprints, 3, tonumber(footprint))
      end
    end

    love.graphics.setColor(50*COLOR_VALUE_FACTOR/255, 50*COLOR_VALUE_FACTOR/255, 50*COLOR_VALUE_FACTOR/255, 200*COLOR_VALUE_FACTOR/255)
    love.graphics.setFont(regular_font)
    love.graphics.printf("Did you know:", 50, height/2 + 25*5, width - 100, "left")
    love.graphics.setFont(small_font)
    love.graphics.printf(factoid_to_show[1], 50, height/2 + 25*5 + regular_font:getHeight(), width - 100, "left")
    love.graphics.setFont(regular_font)
    love.graphics.printf("Remember:", 50, height/2 + 25*5 + regular_font:getHeight() + small_font:getHeight(), width - 100, "left")
    love.graphics.setFont(small_font)
    love.graphics.printf(factoid_to_show[2], 50, height/2 + 25*5 + regular_font:getHeight() + small_font:getHeight() + regular_font:getHeight(), width - 100, "left")
    love.graphics.setColor(91/255, 155/255, 213/255, 40/255)
    love.graphics.rectangle("fill", 0, height/2 + 25*5, width, height)
    
    -- print buttons to continue
    love.graphics.setColor(50*COLOR_VALUE_FACTOR/255, 50*COLOR_VALUE_FACTOR/255, 50*COLOR_VALUE_FACTOR/255, 100*COLOR_VALUE_FACTOR/255)
    love.graphics.setFont(regular_font)
    love.graphics.print("play again", 50, height - regular_font:getHeight() - 10)
    love.graphics.print("acknowledgements", width - 50 - regular_font:getWidth("acknowledgements"), height - regular_font:getHeight() - 10)
  elseif curr_page == "acknowledgements" then
    -- love.graphics.setBackgroundColor(158, 193, 227)
    love.graphics.setBackgroundColor(158/255, 193/255, 227/255)

    -- love.graphics.setColor(40, 40, 40)
    love.graphics.setColor(40/255, 40/255, 40/255)
    love.graphics.setFont(small_font)
    love.graphics.print("Project Manager: Cailin Winston", width/2 - small_font:getWidth("Project Manager: Cailin Winston")/2, height/2 - small_font:getHeight() - 100)
    love.graphics.print("Game Development: Caleb Winston (https://github.com/calebwin)", width/2 - small_font:getWidth("Game Development: Caleb Winston (https://github.com/calebwin)")/2, height/2 - small_font:getHeight())
    love.graphics.print("Graphics/Design: -----------", width/2 - small_font:getWidth("Graphics/Design: -----------")/2, height/2 - small_font:getHeight() + 100)
  end
  
  -- draw transitions
  love.graphics.setColor(50*COLOR_VALUE_FACTOR, 50*COLOR_VALUE_FACTOR, 50*COLOR_VALUE_FACTOR)
  love.graphics.rectangle("fill", 0, -height + transition.y, width, height)
end


function love.mousepressed(x, y, button, istouch, presses)
  timeout_timer = 0
  if transition.page_responsive_timer <= 0 then
    -- is_mouse_clicked = true
  end
end

function love.touchreleased( id, x, y, dx, dy, pressure)
  timeout_timer = 0
  if transition.page_responsive_timer <= 0 then
    is_mouse_clicked = true
  end
end

function love.mousereleased( id, x, y, dx, dy, pressure)
  timeout_timer = 0
  if transition.page_responsive_timer <= 0 then
    is_mouse_clicked = true
  end
end

function love.mousemoved( x, y, dx, dy, istouch)
  timeout_timer = 0
  mouse.x = x
  mouse.y = y
end

function transition_to(to)
  transition.to = to
  transition.to_y = height * 101/100
  transition.page_responsive_timer = 2
end

function mouse_over(x_position, y_position, w_screen, h_screen)
  return mouse.x > x_position and mouse.x < x_position + w_screen and mouse.y > y_position and mouse.y < y_position + h_screen
end

function love.textinput(t)
  timeout_timer = 0
  email = email .. t
end
