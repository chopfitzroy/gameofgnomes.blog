-- GoatCounter tracking pixel.
--
-- Injects an <img> counter pixel into every page, using the page's path
-- (derived from its source .adoc file name) as the `p` query parameter, e.g.
--   site/session-prep.adoc  ->  <img src=".../count?p=/session-prep">
--   site/index.adoc         ->  <img src=".../count?p=/index">
--
-- Config (soupault.toml):
--   endpoint = "https://otis.goatcounter.com/count"  (required)

local endpoint = config["endpoint"]
if not endpoint then
  Plugin.fail("goatcounter widget requires an `endpoint` option, " ..
    "e.g. endpoint = \"https://otis.goatcounter.com/count\"")
end

-- Path of the source file relative to the site directory, e.g.
-- "site/notes/session-prep.adoc" -> "notes/session-prep.adoc".
local site_dir = soupault_config["settings"]["site_dir"]
local rel = Regex.replace_all(page_file, "^" .. site_dir .. "/", "")

-- Drop the file extension: "notes/session-prep.adoc" -> "notes/session-prep".
local slug = Regex.replace(rel, "\\.[^.]+$", "")

local path = "/" .. slug

-- Use the page's first <h1> as the title (this mirrors the `title` widget
-- in soupault.toml). Every page is expected to have an <h1>.
local h1 = HTML.select_one(page, "h1")
if not h1 then
  Plugin.fail("goatcounter widget expected an <h1> on " .. page_file .. " but found none")
end
local title = String.trim(HTML.inner_text(h1))

local pixel = format(
  '<img src="%s?p=%s&t=%s" alt="%s" referrerpolicy="no-referrer-when-downgrade">',
  endpoint, path, title, title
)

-- Append the pixel to the end of <body> so it is part of the final markup.
local body = HTML.select_one(page, "body")
if body then
  HTML.append_child(body, HTML.parse(pixel))
end
