-- Acid Banger
--
-- Endlessly generates two 303
-- patterns and a drum pattern.
--
-- Note: This only outputs
-- MIDI. No sound is generated.
--
-- 0.0.1 @jtopjian
--
-- See the settings pages for
-- all settings.
--
-- E1: Navigate between the 303
-- and drum pages.
--
-- Page 1: 303 patterns
-- K2: Refresh of pattern 1
-- K3: Refresh of pattern 2
--
-- Page 2: Drum
-- K2: Force a refresh of the drum
-- pattern
-- K3: Stop everything
--
-- Based off of The Endless Acid Banger
-- https://github.com/zykure/acid-banger
-- https://github.com/vitling/acid-banger

-- Version
VERSION = "0.0.1"

ThreeOh = include('lib/threeoh')
NineOh = include('lib/nineoh')
Midi = include("lib/midi")
UI = include("lib/ui")

MusicUtil = require "musicutil"
NornsUtil = require "lib.util"
NornsUI = require 'ui'

local first_303_pattern = {}
local first_303_pattern_pos = 0

local second_303_pattern = {}
local second_303_pattern_pos = 0

local pattern_909 = {}
local pattern_909_pos = 0

local SCREEN_FRAMERATE = 15
local screen_refresh_metro
local screen_dirty = true

local first_303_refresh_metro
local second_303_refresh_metro
local drums_refresh_metro
local random_mute_drums_metro

-- autosave parameters
function autosave_clock()
  clock.sleep(30)
  while true do
    params:write()
    clock.sleep(30)
  end
end

-- midi event monitoring
function clock.transport.start()
  first_303_pattern_pos = 0
  second_303_pattern_pos = 0
  pattern_909_pos = 0
  Midi.start()
end

function clock.transport.stop()
  Midi.stop()
end

function clock.transport.reset()
  Midi.stop()
  first_303_pattern_pos = 0
  second_303_pattern_pos = 0
  pattern_909_pos = 0
  Midi.start()
end

function midi_event(data)
  local msg = midi.to_msg(data)
  if msg.type == "start" then
    clock.transport.start()
    Midi.start()
  elseif msg.type == "continue" then
    if Midi.RUNNING then
      clock.transport.stop()
    else
      clock.transport.start()
    end
  end
  if msg.type == "stop" then
    clock.transport.stop()
  end
end

-- event loop
function step()
  local first_303_prev_note_info = {nil, false, false}
  local second_303_prev_note_info = {nil, false, false}

  while true do
    redraw()

    -- Everything runs at 1/4
    -- for now.
    clock.sync(1/4)

    if Midi.RUNNING then
      Midi.all_notes_off("303_1")
      Midi.all_notes_off("303_2")

      if params:get("first_303_enabled") == 1 then
        -- Run the first 303 pattern
        first_303_pattern_pos = NornsUtil.wrap(first_303_pattern_pos+1, 1, 16)
        first_303_note_info = first_303_pattern[first_303_pattern_pos]
        Midi.play_note(first_303_note_info, first_303_prev_note_info, "303_1")
        first_303_prev_note_info = first_303_note_info
      end

      if params:get("second_303_enabled") == 1 then
        -- Run the second 303 pattern
        second_303_pattern_pos = NornsUtil.wrap(second_303_pattern_pos+1, 1, 16)
        second_303_note_info = second_303_pattern[second_303_pattern_pos]
        Midi.play_note(second_303_note_info, second_303_prev_note_info, "303_2")
        second_303_prev_note_info = second_303_note_info
      end

      if params:get("enable_drums") == 1 then
        -- Run the 909 pattern
        pattern_909_pos = NornsUtil.wrap(pattern_909_pos+1, 1, 16)
        Midi.play_drum(pattern_909, pattern_909_pos)
      end
    end
  end
end

-- Screen graphics
function redraw()
  -- clear the screen
  screen.clear()

  pages:redraw()

  -- 303 pattern page
  if pages.index == 1 then
    -- draw the title bar
    UI.draw_title_bar()

    -- draw the first pattern
    draw_pattern_303(1)

    -- draw the second pattern
    draw_pattern_303(2)

  -- 909 pattern page
  elseif pages.index == 2 then
    UI.draw_title_bar()
    draw_pattern_909()
  end
end


-- Draw the 303 pattern
function draw_pattern_303(which)
  local root_note = nil
  local pattern = nil
  local pattern_post = nil
  local screen_y = nil

  if which == 1 then
    root_note = params:get("first_root_note")
    pattern = first_303_pattern
    pattern_pos = first_303_pattern_pos
    screen_y = 32
  else
    root_note = params:get("second_root_note")
    pattern = second_303_pattern
    pattern_pos = second_303_pattern_pos
    screen_y = 64
  end

  step_width = 6
  note_y = screen_y - 4

  screen.level(1)
  screen.line_width(1)
  screen.font_size(8)
  screen_x = 0

  -- Write the note
  local note_info = pattern[pattern_pos]
  if note_info ~= nil and note_info[1] ~= nil then
    screen.move(108, screen_y-10)
    screen.text(MusicUtil.note_num_to_name(note_info[1], true))
  end


  for i=1, 16 do
    if i == pattern_pos then
      screen.level(15)
    else
      screen.level(1)
    end

    screen.move(screen_x, screen_y)
    screen.line_rel(step_width, 0)
    screen.close()
    screen.stroke()

    note_info = pattern[i]
    note = note_info[1]

    if note ~= nil then
      -- Move two pixels up
      screen.move(screen_x, note_y)

      -- if the note is not the root note, move up
      offset = NornsUtil.round((note - root_note) / 2)
      vertical = note_y - offset

      -- If the note is an accent
      if note_info[2] and i ~= pattern_pos then
        screen.level(5)
      end

      note_width = 3
      -- If the note is a slide/tie
      if note_info[3] then
        note_width = 6
      end
      screen.rect(screen_x+2, vertical, note_width, 1)
    end
    screen.stroke()
    screen_x = screen_x + step_width
  end

  screen.update()
end

-- Draw the 909 pattern
function draw_pattern_909()
  screen.level(15)
  screen.line_width(1)
  screen.font_size(8)
  local screen_x = 0
  local screen_y = 64
  screen.move(screen_x, screen_y)

  for key_idx=1, #NineOh.drum_keys do
    local key = NineOh.drum_keys[key_idx]
    screen.level(15)
    if NineOh.drum_mutes[key_idx] == 1 then
      screen.level(3)
    end
    screen.text(key)
    screen.stroke()
    screen_x = screen_x + 14
    screen.move(screen_x, screen_y)
    screen.close()
    for i=1, 16 do
      if i == pattern_909_pos then
        screen.level(15)
      else
        screen.level(1)
      end
      local drum_pattern = pattern_909[key]
      if drum_pattern[i] ~= nil then
        screen.line_rel(0, -5)
        screen.line_rel(4, 0)
        screen.line_rel(0, 5)
        screen.fill()
        screen.close()
        screen.stroke()
      end

      screen_x = screen_x + 7
      screen.move(screen_x, screen_y)
    end
    screen_y = screen_y - 10
    screen_x = 0
    screen.move(screen_x, screen_y)
  end

  screen.update()
end


-- Encoder
function enc(n, delta)
  if n == 1 then
    pages:set_index_delta(NornsUtil.clamp(delta, -1, 1), false)
  end
  screen_dirty = true
end

function key(n, z)
  if z == 1 then
    if pages.index == 1 then
      if n == 2 then
        first_303_pattern = ThreeOh.create_pattern(1)
      end

      if n == 3 then
        second_303_pattern = ThreeOh.create_pattern(2)
      end
    end

    if pages.index == 2 then
      if n == 2 then
        pattern_909 =  NineOh.create_pattern()
      end

      if n == 3 then
        if Midi.RUNNING then
          Midi.RUNNING = 0
          clock.transport.stop()
        else
          Midi.RUNNING = 1
          clock.transport.start()
        end
      end
    end
    screen_dirty = true
  end
end

-- Start here
function init()
  pages = NornsUI.Pages.new(1, 2)

  params:add_separator("ACID BANGER")
  ThreeOh.add_params()
  NineOh.add_params()
  Midi.add_params()
  params:default()
  Midi.midi_out_device.event = midi_event
  autosave_clock_id = clock.run(autosave_clock)

  first_303_pattern = ThreeOh.create_pattern(1)
  second_303_pattern = ThreeOh.create_pattern(2)

  pattern_909 =  NineOh.create_pattern()

  clock.run(step)

  screen_refresh_metro = metro.init()
  screen_refresh_metro.event = function()
    if screen_dirty then
      screen_dirty = false
      redraw()
    end
  end
  screen_refresh_metro:start(1 / SCREEN_FRAMERATE)

  first_303_refresh_metro = metro.init()
  first_303_refresh_metro.event = function()
    if params:get("first_303_refresh") == 1 then
      first_303_pattern = ThreeOh.create_pattern(1)
    end
  end
  first_303_refresh_metro:start(params:get("first_303_refresh_seconds"))

  second_303_refresh_metro = metro.init()
  second_303_refresh_metro.event = function()
    if params:get("second_303_refresh") == 1 then
      second_303_pattern = ThreeOh.create_pattern(2)
    end
  end
  second_303_refresh_metro:start(params:get("second_303_refresh_seconds"))

  drums_refresh_metro = metro.init()
  drums_refresh_metro.event = function()
    if params:get("drums_refresh") == 1 then
      pattern_909 = NineOh.create_pattern()
    end
  end
  drums_refresh_metro:start(params:get("drums_refresh_seconds"))

  random_mute_drums_metro = metro.init()
  random_mute_drums_metro.event = function()
    if params:get("random_mute_drums") == 1 then
      NineOh.mute_drums()
    end
  end
  random_mute_drums_metro:start(60)

end

-- Cleanup here
function cleanup()
  clock.cancel(autosave_clock_id)
  params:write()
end
