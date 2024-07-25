-- 303 Pattern code

MusicUtil = require "musicutil"

local ThreeOh = {}

local density = 1

local offset_choices = {
  {0, 0, 12, 24, 27},
  {0,0,0,12,10,19,26,27},
  {0,1,7,10,12,13},
  {0},
  {0,0,0,12},
  {0,0,12,14,15,19},
  {0,0,0,0,12,13,16,19,22,24,25},
  {0,0,0,7,12,15,17,20,24}
}

function ThreeOh.choose_offset()
  v = math.random(#offset_choices)
  return offset_choices[v]
end

function ThreeOh.build_notes(root_note)
  notes = {}
  offset = ThreeOh.choose_offset()
  for i=1, #offset do
    table.insert(notes, root_note + offset[i])
  end

  return notes
end

function ThreeOh.create_pattern(which)
  if which == 1 then
    root_note = params:get("first_root_note")
  else
    root_note = params:get("second_root_note")
  end

  notes = ThreeOh.build_notes(root_note)
  pattern = {}
  for i=0, 15 do
    chance = 0
    if i % 4 == 0 then
      chance = 0.6
    else
      if i % 3 == 0 then
        chance = 0.5
      else
        if i % 2 == 0 then
          chance = 0.3
        else
          chance = 0.1
        end
      end
    end

    if math.random() < chance then
      v = {}
      -- insert a note
      table.insert(v, notes[math.random(#notes)])
      -- decide if accent
      table.insert(v, math.random() < 0.3)
      -- decide if slide
      table.insert(v, math.random() < 0.1)
      table.insert(pattern, v)
    else
      v = {nil, false, false}
      table.insert(pattern, v)
    end
  end

  return pattern
end

function ThreeOh.add_params()
  params:add_group("303 Options", 8)
  params:add {
    type = "number",
    id = "first_303_enabled",
    name = "First 303 Enabled",
    min = 0,
    max = 1,
    default = 1
  }

  params:add {
		type = "number",
		id = "first_root_note",
    name = "First 303 Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  }

  params:add {
		type = "number",
		id = "first_303_refresh",
    name = "First 303 Refresh",
    min = 0,
    max = 1,
    default = 1,
  }

  params:add {
		type = "number",
		id = "first_303_refresh_seconds",
    name = "First 303 Seconds",
    min = 1,
    max = 600,
    default = 120,
  }

  params:add {
    type = "number",
    id = "second_303_enabled",
    name = "Second 303 Enabled",
    min = 0,
    max = 1,
    default = 1
  }

  params:add {
		type = "number",
		id = "second_root_note",
    name = "Second 303 Root Note",
    min = 0,
    max = 127,
    default = 64,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  }

  params:add {
		type = "number",
		id = "second_303_refresh",
    name = "Second 303 Refresh",
    options = bool_options,
    min = 0,
    max = 1,
    default = 1,
  }

  params:add {
		type = "number",
		id = "second_303_refresh_seconds",
    name = "Second 303 Seconds",
    min = 1,
    max = 600,
    default = 120,
  }
end

return ThreeOh
