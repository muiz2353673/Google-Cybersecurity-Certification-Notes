-- Remote images are often served in a form pdflatex cannot embed; omit in PDF.
function Image (img)
  if img.src:match("^https?://") or img.src:match("%.txt$") then
    local cap = "illustration"
    if img.caption and #img.caption > 0 then
      cap = pandoc.utils.stringify(img.caption)
    end
    return pandoc.Str("[Image omitted: " .. cap .. "]")
  end
end
