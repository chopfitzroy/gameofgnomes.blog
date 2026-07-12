-- Generate per-post share/OG images after the build completes.
--
-- Runs once at the end of the build (see [hooks.post-build] in soupault.toml).
-- For every page in the site index it renders a 1200x630 card into
-- <build_dir>/og/<slug>.png.
--
-- Rendering is delegated to scripts/share-image.sh, which drives ImageMagick.
-- The slug is derived from each entry's clean URL (e.g. "/session-prep/" ->
-- "session-prep"), matching the paths emitted by plugins/og-image.lua.
--
-- The home page is excluded from the site index (it *is* the index view), so
-- it isn't in `site_index`. Its card is rendered separately below using a
-- hardcoded title. This is deliberate: the page's own <h1> stays "All Posts"
-- (best for SEO / search result previews), while the share card can show a
-- more marketing-friendly line -- see HOME_CARD_TITLE.
--
-- Every page must have a title; a missing or empty title is a hard error
-- rather than a silent fallback.
--
-- Note: soupault embeds lua-ml (a Lua ~2.5 dialect). Functions are global
-- `function name()` statements, arrays are walked with `size()` + `while`,
-- and nil is the only falsy value.

-- Title shown on the home page's share/OG card. Intentionally independent of
-- the page's <h1> ("All Posts").
HOME_CARD_TITLE = "A blog about game mastering"

og_dir = Sys.join_path(build_dir, "og")
Sys.mkdir(og_dir)

-- Single-quote a string for safe use in a POSIX shell command.
function shq(s)
  return "'" .. Regex.replace_all(s, "'", "'\\''") .. "'"
end

-- Render one card. Both arguments are shell-quoted so titles with spaces or
-- punctuation reach ImageMagick intact.
function render_card(title, out_path)
  local cmd = "scripts/share-image.sh " .. shq(title) .. " " .. shq(out_path)
  if not Sys.run_program(cmd) then
    Log.error("post-build: failed to render share image for " .. out_path)
  end
end

-- One card per indexed page.
count = 0
n = 1
total = size(site_index)
while (n <= total) do
  local entry = site_index[n]
  local url = entry["url"] or ""
  local slug = Regex.replace_all(url, "^/+", "")
  slug = Regex.replace_all(slug, "/+$", "")

  if slug == "" then
    Plugin.fail("post-build: index entry has an unusable url: " .. url)
  end

  local title = String.trim(entry["title"] or "")
  if title == "" then
    Plugin.fail("post-build: post " .. url .. " has no title; every post must have one")
  end

  render_card(title, Sys.join_path(og_dir, slug .. ".png"))
  count = count + 1
  n = n + 1
end

-- Home page card. Uses a hardcoded title (see above) and renders index.png,
-- matching the /og/index.png path emitted by plugins/og-image.lua.
render_card(HOME_CARD_TITLE, Sys.join_path(og_dir, "index.png"))
count = count + 1

Log.info("post-build: generated " .. count .. " share image(s) into " .. og_dir)
