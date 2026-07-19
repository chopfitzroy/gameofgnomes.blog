-- OpenGraph / Twitter share-image meta tags + share card rendering.
--
-- Runs on every page. Does two things:
--   1. Renders a 1200x630 share card into build/og/<slug>.png using
--      ImageMagick (via scripts/share-image.sh).
--   2. Injects Open Graph and Twitter Card <meta> tags into the page's
--      <head>, pointing at that card.
--
-- The slug is derived from the source .adoc file name, matching both the
-- clean URL soupault emits and the file name the share-image tool writes:
--   site/session-prep.adoc  ->  <site_url>/og/session-prep.png
--
-- Deriving the slug and title here (rather than re-looping the site index in
-- a post-build hook) keeps a single source of truth for both. Because this is
-- a per-page widget, cards are only re-rendered when their page is
-- (re)processed; run soupault with --force for a full rebuild.
--
-- Config (soupault.toml):
--   (none) -- reads site_url from [custom_options].

-- Single-quote a string for safe use in a POSIX shell command.
function shq(s)
  return "'" .. Regex.replace_all(s, "'", "'\\''") .. "'"
end

-- Render one card. Both arguments are shell-quoted so titles with spaces or
-- punctuation reach ImageMagick intact.
function render_card(title, out_path)
  local cmd = "scripts/share-image.sh " .. shq(title) .. " " .. shq(out_path)
  if not Sys.run_program(cmd) then
    Log.error("og-image: failed to render share image for " .. out_path)
  end
end

local site_url = soupault_config["custom_options"]["site_url"]
if not site_url then
  Plugin.fail("og-image widget requires custom_options.site_url to be set")
end

-- Path of the source file relative to the site directory, minus extension:
--   "site/session-prep.adoc" -> "session-prep"
local site_dir = soupault_config["settings"]["site_dir"]
local rel = Regex.replace_all(page_file, "^" .. site_dir .. "/", "")
local slug = Regex.replace(rel, "\\.[^.]+$", "")

-- Every page's card is named after its slug, including the home page
-- (index.adoc -> /og/index.png).
local image_url = site_url .. "/og/" .. slug .. ".png"

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

-- Render the share card into build/og/<slug>.png. This shells out to
-- ImageMagick and is by far the slowest part of a build, yet the generated
-- PNGs are not needed for local previews or for enumerating pages. It is
-- therefore opt-in: set OG_IMAGES=1 (see the build workflow) to render cards.
-- The <meta> tags below are always injected so page output is identical
-- whether or not the images exist. Sys.mkdir is idempotent.
if Sys.getenv("OG_IMAGES", nil) then
  local og_dir = Sys.join_path(build_dir, "og")
  Sys.mkdir(og_dir)
  render_card(title, Sys.join_path(og_dir, slug .. ".png"))
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
