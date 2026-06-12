-- GoatCounter tracking pixel.
--
-- Injects an <img> counter pixel into every page, using the page's path
-- (derived from its source .md file name) as the `p` query parameter, e.g.
--   site/session-prep.md  ->  <img src=".../count?p=/session-prep">
--   site/index.md         ->  <img src=".../count?p=/">
--
-- Config (soupault.toml):
--   endpoint = "https://otis.goatcounter.com/count"  (required)

local endpoint = config["endpoint"]
if not endpoint then
  Plugin.fail("goatcounter widget requires an `endpoint` option, " ..
    "e.g. endpoint = \"https://otis.goatcounter.com/count\"")
end

-- Path of the source file relative to the site directory, e.g.
-- "site/notes/session-prep.md" -> "notes/session-prep.md".
local site_dir = soupault_config["settings"]["site_dir"]
local rel = Regex.replace_all(page_file, "^" .. site_dir .. "/", "")

-- Drop the file extension: "notes/session-prep.md" -> "notes/session-prep".
local slug = Regex.replace(rel, "\\.[^.]+$", "")

local path = "/" .. slug

local pixel = format(
  '<img src="%s?p=%s" alt="" referrerpolicy="no-referrer-when-downgrade">',
  endpoint, path
)

-- Append the pixel to the end of <body> so it is part of the final markup.
local body = HTML.select_one(page, "body")
if body then
  HTML.append_child(body, HTML.parse(pixel))
end
