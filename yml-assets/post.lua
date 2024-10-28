
-- HTML Filters
if quarto.doc.is_format("html") then
  local accordion_count = 0
  -- Accordion
  function Div(el)
    if el.classes:includes("accordion") then
      accordion_count = accordion_count + 1
      local id = "accordion-" .. accordion_count
      local target = "." .. id .. "-contents"
      
      -- Get title from attributes or use default
      local title = el.attributes.title or "Click/Tap to expand."
      
      -- Remove title from attributes
      el.attributes.title = nil
      
      -- Convert content to HTML
      local content = pandoc.write(pandoc.Pandoc(el.content), 'html')
      
      -- Create the new HTML structure
      local html = string.format([[
  <div class="callout callout-style-simple accordion callout-note no-icon callout-titled">
    <div class="callout-header d-flex align-content-center" data-bs-toggle="collapse" data-bs-target="%s" aria-controls="%s" aria-expanded="false" aria-label="Toggle callout">
      <div class="callout-icon-container">
        <i class="callout-icon no-icon"></i>
      </div>
      <div class="callout-title-container flex-fill">
        %s
      </div>
      <button class="callout-btn-toggle d-inline-block border-0 py-1 ps-1 pe-0 float-end"><i class="callout-toggle"></i></button>
    </div>
    <div id="%s" class="%s callout-collapse collapse">
      <div class="callout-body-container callout-body">
        %s
      </div>
    </div>
  </div>
      ]], target, id, title, id, id .. "-contents", content)
      
      -- Return as RawBlock
      return pandoc.RawBlock('html', html)
    end
    return el
  end
end
