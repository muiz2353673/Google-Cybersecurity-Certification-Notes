-- Comprehensive Pandoc Lua filter for PDF conversion of these course notes.
-- Handles: remote images, backslash sequences in inline code, deep nesting.

-- 1. Strip remote images (pdflatex / xelatex can't fetch and include them)
function Image (img)
  if img.src:match("^https?://") or img.src:match("%.txt$") then
    local cap = "illustration"
    if img.caption and #img.caption > 0 then
      cap = pandoc.utils.stringify(img.caption)
    end
    return pandoc.Str("[Image: " .. cap .. "]")
  end
end

-- 2. Protect backslash sequences inside Code (inline `\w`, `\n`, etc.)
--    Pandoc Code inlines are already verbatim, but some notes have bare \w
--    outside code fences that LaTeX reads as commands. We wrap them in Code.
function Str (el)
  if el.text:match("\\[a-zA-Z]") then
    return pandoc.Code(el.text)
  end
end

-- 3. Flatten deeply-nested bullet lists (>4 levels) to max 4 levels.
--    BasicTeX without enumitem only supports 4 itemize levels.
local function flatten_list(bl, depth)
  depth = depth or 1
  local items = {}
  for _, item in ipairs(bl.content) do
    if depth >= 4 then
      local flat = {}
      for _, block in ipairs(item) do
        if block.t == "BulletList" or block.t == "OrderedList" then
          for _, sub_item in ipairs(block.content) do
            for _, sub_block in ipairs(sub_item) do
              flat[#flat + 1] = sub_block
            end
          end
        else
          flat[#flat + 1] = block
        end
      end
      items[#items + 1] = flat
    else
      local new_item = {}
      for _, block in ipairs(item) do
        if block.t == "BulletList" then
          new_item[#new_item + 1] = flatten_list(block, depth + 1)
        elseif block.t == "OrderedList" then
          new_item[#new_item + 1] = flatten_list(block, depth + 1)
        else
          new_item[#new_item + 1] = block
        end
      end
      items[#items + 1] = new_item
    end
  end
  if bl.t == "OrderedList" then
    return pandoc.OrderedList(items, bl.listAttributes)
  end
  return pandoc.BulletList(items)
end

function BulletList (bl)
  return flatten_list(bl, 1)
end

function OrderedList (bl)
  return flatten_list(bl, 1)
end
