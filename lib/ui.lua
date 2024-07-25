-- UI functions

local UI = {}

function UI.draw_title_bar()
  -- Draw bar
  screen.level(10)
  screen.line_width(8)
  screen.move(0, 3)
  screen.line(127, 3)
  screen.close()
  screen.stroke()
  screen.fill()
  screen.font_face(1)
  screen.font_size(8)

  -- Draw title
  screen.level(0)
  screen.move(2, 6)
  screen.text("ACID BANGER")
  screen.fill()

  screen.move(125, 6)
  screen.text_right(params:get("clock_tempo") .. "bpm")
  screen.fill()
end


function UI.draw_pattern(pattern, label, x, y)
end


return UI
