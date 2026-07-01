-- Post source link.
--
-- Appends a link to the post's source file (on GitHub) at the bottom of
-- each note's <main>, e.g.
--   site/session-prep.adoc ->
--     https://github.com/chopfitzroy/gameofgnomes.blog/blob/main/site/session-prep.adoc

local prefix = "https://github.com/chopfitzroy/gameofgnomes.blog/blob/main/"

-- `page_file` is the source path relative to the project root, e.g.
-- "site/session-prep.adoc", which is exactly what we append to the prefix.
local url = prefix .. page_file

local link = format(
  '<p class="source-link"><a href="%s">View source</a></p>',
  url
)

-- Append the link to the end of <main> so it renders below the content.
local main = HTML.select_one(page, "main")
if main then
  HTML.append_child(main, HTML.parse(link))
end
