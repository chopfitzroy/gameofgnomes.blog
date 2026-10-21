-- GoatCounter tracking (CSS background-image).
--
-- Injects a <style> block into every page that fetches the GoatCounter
-- counter endpoint via `background-image` on <body>, using the page's path
-- (derived from its source .adoc file name) as the `p` query parameter, e.g.
--   site/session-prep.adoc  ->  background-image: url(".../count?p=/session-prep")
--   site/index.adoc         ->  background-image: url(".../count?p=/index")
--
-- We use `background-image` (a smolweb Grade-A CSS property) rather than an
-- <img> pixel: an empty `alt` trips the validator's accessibility warning,
-- and `referrerpolicy` is not part of the HTML subset. The /count endpoint
-- returns a 1x1 transparent GIF, so it stays invisible.
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

local style = format(
  '<style>body{background-image:url("%s?p=%s&t=%s")}</style>',
  endpoint, path, title
)

-- Append the <style> to the end of <head> so it is part of the final markup.
local head = HTML.select_one(page, "head")
if head then
  HTML.append_child(head, HTML.parse(style))
end
