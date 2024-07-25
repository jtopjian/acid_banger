-- 909 Pattern code

MusicUtil = require "musicutil"

local NineOh = {}
NineOh.drum_notes = {
  ["BD"] = 60,
  ["SD"] = 60,
  ["CP"] = 60,
  ["CH"] = 60,
  ["OH"] = 60
}

NineOh.drum_keys = {"BD", "SD", "CP", "CH", "OH"}
NineOh.drum_mutes = {0, 0, 0, 0, 0}

local bd_mode = {"electro", "fourfloor"}
local sd_mode = {"backbeat", "skip"}
local cp_mode = {"backbeat", "skip"}
local hat_mode = {"offbeats", "skip"}
local density = 1

function NineOh.create_pattern()
  local pattern = {
    ["BD"] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
    ["SD"] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
    ["CP"] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
    ["CH"] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil},
    ["OH"] = {nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil}
  }

  -- BD / Kick
  if bd_mode[math.random(#bd_mode)] == "fourfloor" then
    for i=0, 15 do
      if i % 4 == 0 then
        pattern["BD"][i+1] = 0.9
      elseif i % 2 == 0 and math.random() < 0.1 then
        pattern["BD"][i+1] = 0.6
      end
    end
  else
    for i=0, 15 do
      if i == 0 then
        pattern["BD"][i+1] = 1
      elseif i % 2 == 0 and i % 8 ~= 4 and math.random() < 0.5 then
        pattern["BD"][i+1] = math.random() * 0.9
      elseif math.random() < 0.05 then
        pattern["BD"][i+1] = math.random() * 0.9
      end
    end
  end

  -- SD / Snare
  if sd_mode[math.random(#sd_mode)] == "backbeat" then
    for i=0, 15 do
      if i % 8 == 4 then
        pattern["SD"][i+1] = 1
      end
    end
  else
    for i=0, 15 do
      if i % 8 == 3 or i % 8 == 6 then
        pattern["SD"][i+1] = 0.6 + math.random() * 0.4
      elseif i % 2 == 0 and math.random() < 0.2 then
        pattern["SD"][i+1] = 0.4 + math.random() * 0.2
      elseif math.random() < 0.1 then
        pattern["SD"][i+1] = 0.2 + math.random() * 0.2
      end
    end
  end

  -- CP / Clap
  if cp_mode[math.random(#cp_mode)] == "backbeat" then
    for i=0, 15 do
      if i % 8 == 4 then
        pattern["CP"][i+1] = 0.5
      elseif i % 8 == 5 and pattern["SD"][i-1] ~= nil then
        pattern["CP"][i+1] = 0.3 + math.random() * 0.2
      end
    end
  else
    for i=0, 15 do
      if i % 8 == 3 or i % 8 == 6 then
        pattern["CP"][i+1] = 0.5 + math.random() * 0.3
      elseif (i % 8 == 4 or i % 8 == 7) and pattern["SD"][i-1] ~= nil and math.random() < 0.5 then
        pattern["CP"][i+1] = 0.3 + math.random() * 0.2
      elseif i % 2 == 0 then
        local _v = 0.4
        if pattern["SD"][i] ~= nil then
          _v = 0.2
        end
        if math.random() < _v then
          pattern["CP"][i+1] = 0.4 + math.random() * 0.1
        end
      elseif math.random() < 0.1 then
        pattern["CP"][i+1] = 0.1 + math.random() * 0.1
      end
    end
  end

  -- Hats
  if hat_mode[math.random(#hat_mode)] == "offbeats" then
    for i=0, 15 do
      if i % 4 == 2 then
        pattern["OH"][i+1] = 0.4
      elseif math.random() < 0.3 then
        if math.random() < 0.5 then
          pattern["CH"][i+1] = 0.2 + math.random() * 0.2
        else
          pattern["OH"][i+1] = 0.1 + math.random() * 0.2
        end
      end
    end
  else
    for i=0, 15 do
      if i % 2 == 0 then
        pattern["CH"][i+1] = 0.4
      elseif math.random() < 0.5 then
        pattern["CH"][i+1] = 0.2 + math.random() * 0.3
      end
    end
  end

  return pattern
end

function NineOh.mute_drums()
  for key_idx=1, #NineOh.drum_keys do
    NineOh.drum_mutes[key_idx] = 0
  end
  if math.random() > 0.3 then
    random_key = math.random(#NineOh.drum_keys)
    NineOh.drum_mutes[random_key] = 1
  end
end

function NineOh.add_params()
  params:add_group("909 Options", 9)
  params:add {
    type = "number",
    id = "enable_drums",
    name = "Enable Drums",
    min = 0,
    max = 1,
    default = 1,
  }

  params:add {
    type = "number",
    id = "drums_refresh",
    name = "Refresh Drums",
    min = 0,
    max = 1,
    default = 1,
  }

  params:add {
    type = "number",
    id = "drums_refresh_seconds",
    name = "Refresh Drums Seconds",
    min = 1,
    max = 600,
    default = 330,
  }

  params:add {
    type = "number",
    id = "random_mute_drums",
    name = "Randomly Mute Drums",
    min = 0,
    max = 1,
    default = 1,
  }

  params:add {
    type = "number",
    id = "root_note_bd",
    name = "BD Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      NineOh.drum_notes["BD"] = x
    end
  }

  params:add {
    type = "number",
    id = "root_note_sd",
    name = "SD Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      NineOh.drum_notes["SD"] = x
    end
  }

  params:add {
    type = "number",
    id = "root_note_cp",
    name = "CP Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      NineOh.drum_notes["CP"] = x
    end
  }

  params:add {
    type = "number",
    id = "root_note_ch",
    name = "CH Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      NineOh.drum_notes["CH"] = x
    end
  }

  params:add {
    type = "number",
    id = "root_note_oh",
    name = "OH Root Note",
    min = 0,
    max = 127,
    default = 60,
    formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
    action = function(x)
      NineOh.drum_notes["OH"] = x
    end
  }
end


return NineOh
