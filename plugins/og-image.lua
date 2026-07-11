-- OpenGraph / Twitter share-image meta tags.
--
-- Injects Open Graph and Twitter Card <meta> tags into every page's <head>,
-- pointing at the per-post share card generated into build/og/<slug>.png by
-- scripts/build-share-images.sh.
--
-- The slug is derived from the source .adoc file name, matching both the
-- clean URL soupault emits and the file name the share-image tool writes:
--   site/session-prep.adoc  ->  <site_url>/og/session-prep.png
--
-- The home page (index.adoc) has no per-post card, so it falls back to a
-- site-wide default at <site_url>/og/default.png.
--
-- Config (soupault.toml):
--   (none) -- reads site_url from [custom_options].

local site_url = soupault_config["custom_options"]["site_url"]
if not site_url then
  Plugin.fail("og-image widget requires custom_options.site_url to be set")
end

-- Path of the source file relative to the site directory, minus extension:
--   "site/session-prep.adoc" -> "session-prep"
local site_dir = soupault_config["settings"]["site_dir"]
local rel = Regex.replace_all(page_file, "^" .. site_dir .. "/", "")
local slug = Regex.replace(rel, "\\.[^.]+$", "")

-- The home page gets a site-wide default card; posts get their own.
local image_slug = slug
if slug == "index" then
  image_slug = "default"
end

local image_url = site_url .. "/og/" .. image_slug .. ".png"

-- Title: the page's first <h1>, mirroring the `title` widget. Fall back to
-- the site name for safety.
local title = "Game of Gnomes"
local h1 = HTML.select_one(page, "h1")
if h1 then
  title = String.trim(HTML.inner_text(h1))
end

-- Description: the first content <p> inside <main>. This precedes the
-- appended ".source-link" paragraph, so the first match is real body copy.
-- Left empty (tags omitted) when a page has no paragraph.
local description = nil
if slug == "index" then
  -- The home page is the index list, not an article; use the site tagline.
  description = "A blog about playing tabletop roleplaying games"
else
  local first_p = HTML.select_one(page, "main p")
  if first_p then
    local text = String.trim(HTML.inner_text(first_p))
    if text ~= "" then
      description = text
    end
  end
end

-- Canonical page URL. Clean URLs mean the home page is the site root and every
-- other page is "<site_url>/<slug>/".
local page_url = site_url .. "/"
if slug ~= "index" then
  page_url = site_url .. "/" .. slug .. "/"
end

local tags = format([[
<meta property="og:type" content="website">
<meta property="og:title" content="%s">
<meta property="og:url" content="%s">
<meta property="og:image" content="%s">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="%s">
<meta name="twitter:image" content="%s">
]], title, page_url, image_url, title, image_url)

local head = HTML.select_one(page, "head")
if head then
  HTML.append_child(head, HTML.parse(tags))

  -- Description tags, only when the page actually has body copy.
  if description then
    local desc_tags = format([[
<meta name="description" content="%s">
<meta property="og:description" content="%s">
<meta name="twitter:description" content="%s">
]], description, description, description)
    HTML.append_child(head, HTML.parse(desc_tags))
  end
end
