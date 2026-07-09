local iso = Sys.get_program_output(
  "PAGE_FILE='" .. page_file .. "' scripts/git-last-modified"
)

iso = String.trim(iso or "")

if iso == "" then
  -- Fallback: today's date in YYYY-MM-DD. os.date isn't available in
  -- soupault's embedded Lua, so get it via the shell.
  iso = String.trim(Sys.get_program_output("date +%Y-%m-%d") or "")
end

local pretty = Date.reformat(iso, {"%F"}, "%b %-d, %Y")

local time_tag = format(
  '<time class="note-date" datetime="%s">%s</time>',
  iso, pretty
)

if not Regex.match(page_source, "<h1") then
  Plugin.fail(
    "Note " .. page_file .. " has no top-level heading. " ..
    "Every note must start with a `# Title` line."
  )
end

page_source = Regex.replace(page_source, "<h1", time_tag .. "\n<h1")
