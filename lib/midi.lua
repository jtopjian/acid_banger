-- MIDI Functions

MusicUtil = require "musicutil"
NineOh = include('lib/nineoh')

local midi_out = {}

midi_out.midi_out_device = nil
midi_out.accent_velocity = 127
midi_out.velocity = 100
midi_out.RUNNING = true

midi_out.channels = {
  ["303_1"] = nil,
  ["303_2"] = nil,
  ["BD"] = nil,
  ["SD"] = nil,
  ["CP"] = nil,
  ["CH"] = nil,
  ["OH"] = nil
}

-- MIDI Parameters
function midi_out.add_params()
  local devices = {}
  for id, device in pairs(midi.vports) do
    devices[id] = device.name
  end

  params:add_group("MIDI", 10)

  -- Add MIDI device param
  params:add {
    type = "option",
    id = "midi_device",
    name = "Device",
    options = devices,
    default = 1,
    action = function(x)
      midi_out.midi_out_device = midi.connect(x)
    end
  }

  -- Add MIDI channel for the first 303
  params:add {
    type = "number",
    id = "midi_channel_303_1",
    name = "First 303 Channel",
    min = 1,
    max = 16,
    default = 1,
    action = function(x)
      midi_out.channels["303_1"] = x
      midi_out.all_notes_off("303_1")
    end
  }

  -- Add MIDI channel for the second 303
  params:add {
    type = "number",
    id = "midi_channel_303_2",
    name = "Second 303 Channel",
    min = 1,
    max = 16,
    default = 2,
    action = function(x)
      midi_out.channels["303_2"] = x
      midi_out.all_notes_off("303_2")
    end
  }

  -- Add accent velocity param
  params:add {
    type = "number",
    id = "accent_velocity",
    name = "Accent Velocity",
    min = 0,
    max = 127,
    default = 127,
    action = function(x)
      midi_out.accent_velocity = x
    end
  }

  -- Add velocity param
  params:add {
    type = "number",
    id = "velocity",
    name = "Velocity",
    min = 0,
    max = 127,
    default = 100,
    action = function(x)
      midi_out.velocity = x
    end
  }

  -- Add MIDI channel for the BD
  params:add {
    type = "number",
    id = "midi_channel_bd",
    name = "BD Channel",
    min = 1,
    max = 16,
    default = 3,
    action = function(x)
      midi_out.channels["BD"] = x
      midi_out.all_notes_off("BD")
    end
  }

  -- Add MIDI channel for the SD
  params:add {
    type = "number",
    id = "midi_channel_sd",
    name = "SD Channel",
    min = 1,
    max = 16,
    default = 4,
    action = function(x)
      midi_out.channels["SD"] = x
      midi_out.all_notes_off("SD")
    end
  }

  -- Add MIDI channel for the CP
  params:add {
    type = "number",
    id = "midi_channel_cp",
    name = "CP Channel",
    min = 1,
    max = 16,
    default = 5,
    action = function(x)
      midi_out.channels["CP"] = x
      midi_out.all_notes_off("CP")
    end
  }

  -- Add MIDI channel for the CH
  params:add {
    type = "number",
    id = "midi_channel_ch",
    name = "CH Channel",
    min = 1,
    max = 16,
    default = 6,
    action = function(x)
      midi_out.channels["CH"] = x
      midi_out.all_notes_off("CH")
    end
  }

  -- Add MIDI channel for the OH
  params:add {
    type = "number",
    id = "midi_channel_oh",
    name = "OH Channel",
    min = 1,
    max = 16,
    default = 7,
    action = function(x)
      midi_out.channels["OH"] = x
      midi_out.all_notes_off("OH")
    end
  }
end

-- Logic was taken from bline
-- https://github.com/toneburst/bline/
function midi_out.play_note(note_info, prev_note_info, channel)
  local rest = false
  if note_info[1] == nil then
    rest = true
  end

  local velocity = midi_out.velocity
  if note_info[2] then
    velocity = midi_out.accent_velocity
  end

  local step_length = clock.get_beat_sec() / 4
  local tie = note_info[1] ~= nil and (note_info[1] == prev_note_info[1])

  -- if there is no note in the pattern
  if rest then
    -- and if the previous note was a slide
    if prev_note_info[3] then
      -- then turn it off
      midi_out.midi_out_device:note_off(prev_note_info[1], midi_out.channels[channel])
    end
  -- if there is a note playing
  -- and if the previous note is a slide
  elseif prev_note_info[3] then
    -- if the current note is a slide, too
    if note_info[3] then
      -- and if it's a different note
      if tie == false then
        midi_out.note_on(note_info[1], velocity, channel)

        if prev_note_info[1] ~= nil then
          clock.run(midi_out.schedule_previous_note_off, prev_note_info[1], step_length, channel)
        end
      end
    else
      if tie == false then
        midi_out.note_on(note_info[1], velocity, channel)
      end
      if prev_note_info[1] ~= nil then
        clock.run(midi_out.schedule_previous_note_off, prev_note_info[1], step_length, channel)
      end

      if note_info[1] ~= nil then
        clock.run(midi_out.schedule_note_off, note_info[1], step_length, channel)
      end
    end
  else
    if note_info[3] then
      midi_out.note_on(note_info[1], velocity, channel)
    else
      midi_out.note_on(note_info[1], velocity, channel)
      if note_info[1] ~= nil then
        clock.run(midi_out.schedule_note_off, note_info[1], step_length, channel)
      end
    end
  end
end

function midi_out.play_drum(pattern, pos)
  local step_length = clock.get_beat_sec() / 4

  for key_idx=1, #NineOh.drum_keys do
    local key = NineOh.drum_keys[key_idx]
    if pattern[key][pos] ~= nil then
      if NineOh.drum_mutes[key_idx] ~= 1 then
        local note = NineOh.drum_notes[key]
        local vel = math.floor(pattern[key][pos] * 127)
        midi_out.note_on(note, vel, key)
        clock.run(midi_out.schedule_note_off, note, step_length, key)
      end
    end
  end
end

-- MIDI Functions
function midi_out.start()
  midi_out.RUNNING = true
  midi_out.all_notes_off("303_1")
  midi_out.all_notes_off("303_2")
  midi_out.all_notes_off("BD")
  midi_out.all_notes_off("SD")
  midi_out.all_notes_off("CP")
  midi_out.all_notes_off("CH")
  midi_out.all_notes_off("OH")
end

function midi_out.stop()
  midi_out.RUNNING = false
  midi_out.all_notes_off("303_1")
  midi_out.all_notes_off("303_2")
  midi_out.all_notes_off("BD")
  midi_out.all_notes_off("SD")
  midi_out.all_notes_off("CP")
  midi_out.all_notes_off("CH")
  midi_out.all_notes_off("OH")
end

function midi_out.note_on(note, velocity, channel)
  midi_out.midi_out_device:note_on(note, velocity, midi_out.channels[channel])
end

function midi_out.note_off(note, channel)
  if midi_out.midi_out_device ~= nil then
    midi_out.midi_out_device:note_off(note, nil, midi_out.channels[channel])
  end
end

function midi_out.schedule_note_off(note, step_length, channel)
  local sleeptime = step_length * 0.5
  clock.sleep(sleeptime)
  midi_out.note_off(note, channel)
end

function midi_out.schedule_previous_note_off(note, step_length, channel)
  local sleeptime = step_length * 0.01
  clock.sleep(sleeptime)
  midi_out.note_off(note_info, channel)
end

function midi_out.all_notes_off(channel)
  if midi_out.midi_out_device ~= nil then
    midi_out.midi_out_device:cc(123, 0, midi_out.channels[channel])
  end
end

function midi_out.init()
  midi_out.midi_out_device = midi.connect(1)
  midi_out.midi_out_device.event = function() end

  midi_out.paramGroupName = "MIDI Output"
  midi_out.addParams()
  midi_out.all_notes_off()
end

return midi_out
