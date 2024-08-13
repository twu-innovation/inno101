
-- learning-activity
  -- re-purposes"callout-note"
  function Div(div)
    if div.classes:includes("learning-activity") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = div.attributes.title and ("Learning Activity: " .. div.attributes.title) or "Learning Activity",
        appearance = div.attributes.appearance or "default",
        icon = div.attributes.icon or false
      })
    end
    -- note
    if div.classes:includes("note") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        -- title = "Note:",
        appearance = div.attributes.appearance or "simple",
        icon = div.attributes.icon or false
      })
    end
  end
