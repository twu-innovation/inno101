-- HTML Filters 
if quarto.doc.is_format("html") then
-- Repurposes the Quarto native 'note' Callout.
  function Div(div)
    -- learning-activity
    if div.classes:includes("learning-activity") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = div.attributes.title or " ",
        appearance = div.attributes.appearance or "default",
        icon = false
      })
    end
    -- check
    if div.classes:includes("check") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = "Checking Your Learning",
        appearance = div.attributes.appearance or "default",
        icon = false
      })
    end
    -- note
    if div.classes:includes("note") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        appearance = div.attributes.appearance or "simple",
        icon = div.attributes.icon or false
      })
    end
    -- prote
    if div.classes:includes("prote") then
      local comment_lines = {"<!-- !!! Prote:"}
      
      local function add_inline_content(inline, line)
        if inline.t == "Str" then
          return line .. inline.text
        elseif inline.t == "Space" then
          return line .. " "
        else
          return line .. pandoc.utils.stringify(inline)
        end
      end
    
      for _, item in ipairs(div.content) do
        if item.t == "Para" then
          local line = ""
          for _, inline in ipairs(item.content) do
            if inline.t == "SoftBreak" then
              table.insert(comment_lines, line)
              line = ""
            else
              line = add_inline_content(inline, line)
            end
          end
          if line ~= "" then
            table.insert(comment_lines, line)
          end
        elseif item.t == "Plain" then
          local line = pandoc.utils.stringify(item)
          table.insert(comment_lines, line)
        end
      end
      
      table.insert(comment_lines, "-->")
      
      local html_comment = table.concat(comment_lines, "\n")
      return pandoc.RawBlock('html', html_comment)
    end
  end
  -- Responsive tables
  function Table(el)
    -- Create the table container div
    local table_container = pandoc.Div(el, pandoc.Attr("", {"table-container"}))
    
    -- Create the parent container div
    local parent_container = pandoc.Div(table_container, pandoc.Attr("", {"parent-table-container"}))
    
    -- Return the nested structure
    return parent_container
  end
end

-- PDF Filters
if quarto.doc.is_format("pdf") then
  -- The function below repurposes the Quarto native 'note' Callout.
  function Div(div)
    -- learning-activity
    if div.classes:includes("learning-activity") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = div.attributes.title and ("Learning Activity: " .. div.attributes.title) or "Learning Activity",
        appearance = div.attributes.appearance or "default",
        icon = false
      })
    end
    -- check
    if div.classes:includes("check") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = "Checking Your Learning",
        appearance = div.attributes.appearance or "default",
        icon = false
      })
    end
    -- note
    if div.classes:includes("note") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        appearance = div.attributes.appearance or "simple",
        icon = div.attributes.icon or false
      })
    end
    -- accordion
    if div.classes:includes("accordion") then
      return quarto.Callout({
        type = "note",
        content = div.content,
        title = div.attributes.title or "Open to learn more.",
        appearance = div.attributes.appearance or "simple",
        icon = false,
        collapse = div.attributes.collapse or true
      })
    end
    -- prote
    if div.classes:includes("prote") then
      local comment_lines = {"<!-- !!! Prote:"}
      
      local function add_inline_content(inline, line)
        if inline.t == "Str" then
          return line .. inline.text
        elseif inline.t == "Space" then
          return line .. " "
        else
          return line .. pandoc.utils.stringify(inline)
        end
      end
    
      for _, item in ipairs(div.content) do
        if item.t == "Para" then
          local line = ""
          for _, inline in ipairs(item.content) do
            if inline.t == "SoftBreak" then
              table.insert(comment_lines, line)
              line = ""
            else
              line = add_inline_content(inline, line)
            end
          end
          if line ~= "" then
            table.insert(comment_lines, line)
          end
        elseif item.t == "Plain" then
          local line = pandoc.utils.stringify(item)
          table.insert(comment_lines, line)
        end
      end
      
      table.insert(comment_lines, "-->")
      
      local html_comment = table.concat(comment_lines, "\n")
      return pandoc.RawBlock('html', html_comment)
    end
  end
end


-- Docx Filters
if quarto.doc.is_format("docx") then
  local in_callout = false

  -- Decode HTML
  local function decode_html_entities(str)
    return str:gsub("&amp;", "&"):gsub("&lt;", "<"):gsub("&gt;", ">"):gsub("&quot;", '"'):gsub("&#39;", "'")
  end
  -- Handle H5p 
  local function process_h5p_iframe(el)
    if el.text:match('<iframe[^>]+src="[^"]+"[^>]*>') then
      local src = el.text:match('src="([^"]+)"')
      if src and src:match("h5p_embed") then
        -- Decode the URL
        src = decode_html_entities(src)
        return pandoc.Para(pandoc.Link(src, src))
      end
    end
    return el
  end

  -- Handle callouts
  local function process_callouts(div)
    if in_callout then
      return div
    end
    -- Reworks default tabled callouts (used for prote only)
    local function create_callout(type, content, title, appearance, icon)
      in_callout = true
      local result = quarto.Callout({
        type = type,
        content = pandoc.walk_block(pandoc.Div(content), {Div = process_div}),
        title = title,
        appearance = appearance or "default",
        icon = icon
      })
      in_callout = false
      return result
    end
    -- Defines the text to display around the callout type in doc
    local function create_custom_div(type, content, title, icon, color)
      in_callout = true
      local opening_line = "--- Begin " .. type
      if title then
        opening_line = opening_line .. ": " .. title
      end
      if icon then
        opening_line = opening_line .. " (w/ icon)"
      end
      opening_line = opening_line .. " ---"
      
      local closing_line = "--- End " .. type .. " ---"
      
      -- text styles in doc
      local function styled_text(text, color)
        return pandoc.RawInline('openxml', 
          string.format('<w:r><w:rPr><w:color w:val="%s"/><w:sz w:val="16"/></w:rPr><w:t>%s</w:t></w:r>', color, text))
      end
      
      local result = pandoc.Div({
        pandoc.Para(styled_text(opening_line, color)),
        pandoc.walk_block(pandoc.Div(content), {Div = process_div}),
        pandoc.Para(styled_text(closing_line, color))
      })
      
      in_callout = false
      return result
    end
    -- handling of callout types, includes color in doc
    if div.classes:includes("learning-activity") then
      return create_custom_div("Learning Activity", div.content, div.attributes.title, div.attributes.icon, "2375DA")  -- Blue
    elseif div.classes:includes("check") then
      return create_custom_div("Checking Your Learning", div.content, nil, div.attributes.icon, "96958E")  -- Grey
    elseif div.classes:includes("note") then
      return create_custom_div("Note", div.content, nil, div.attributes.icon, "198402")  -- Green
    elseif div.classes:includes("accordion") then
      -- Accordion
      return create_custom_div("Accordion", div.content, div.attributes.title, div.attributes.icon, "4F1896")  -- Purple
    elseif div.classes:includes("prote") then
      return create_callout("important", div.content, "Note from Production", div.attributes.appearance or "simple", true)
    else
      return div 
    end
  end

  function Div(div)
    local result = process_callouts(div)
    -- Process any RawBlock elements within the div
    return pandoc.walk_block(result, {RawBlock = process_h5p_iframe})
  end

  function RawBlock(el)
    return process_h5p_iframe(el)
  end
  -- Removes identifiers from headings in doc
  function Header(el)
    el.identifier = ""
    return el
  end

end


