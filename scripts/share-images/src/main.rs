//! Generate share/OG images for each blog post.
//!
//! Reads the Soupault-generated `index.json` (list of posts) and writes one
//! PNG per post into the build output. Each card is a white 1200x630 rectangle
//! with "Game of Gnomes" centered at the top, a 2px black rule beneath it, and
//! the post title centered in the middle.
//!
//! Fonts: MonaSans variable font is loaded directly from the site's `.woff2`.
//! takumi decodes WOFF2 natively and drives the `wght`/`opsz` axes via CSS
//! `font-weight`, so no static-instance pre-processing is needed.
//!
//! Usage:
//!   share-images <index.json> <fonts-dir> <output-dir>
//!
//! Output files are named after each post's URL slug, e.g. `/session-prep/`
//! becomes `<output-dir>/session-prep.png`.

use std::fs;
use std::path::Path;
use std::process::ExitCode;

use serde::Deserialize;
use takumi::prelude::{
    FontOverride, FontResource, Fonts, FromHtml, FromHtmlOptions, Node, OutputFormat,
    RenderOptions, Viewport,
};
use takumi::{render, write_image};

type BoxError = Box<dyn std::error::Error>;

const WIDTH: u32 = 1200;
const HEIGHT: u32 = 630;
const FONT_FAMILY: &str = "Mona Sans";
const SITE_TITLE: &str = "Game of Gnomes";
const DEFAULT_TAGLINE: &str = "A blog about playing tabletop roleplaying games";

#[derive(Debug, Deserialize)]
struct IndexEntry {
    url: String,
    title: String,
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().collect();
    if args.len() != 4 {
        eprintln!("usage: {} <index.json> <fonts-dir> <output-dir>", args[0]);
        return ExitCode::FAILURE;
    }
    let index_path = Path::new(&args[1]);
    let fonts_dir = Path::new(&args[2]);
    let output_dir = Path::new(&args[3]);

    match run(index_path, fonts_dir, output_dir) {
        Ok(count) => {
            println!("share-images: wrote {count} card(s) to {}", output_dir.display());
            ExitCode::SUCCESS
        }
        Err(err) => {
            eprintln!("share-images: error: {err}");
            ExitCode::FAILURE
        }
    }
}

fn run(index_path: &Path, fonts_dir: &Path, output_dir: &Path) -> Result<usize, BoxError> {
    let raw = fs::read_to_string(index_path)
        .map_err(|e| format!("reading {}: {e}", index_path.display()))?;
    let entries: Vec<IndexEntry> = serde_json::from_str(&raw)
        .map_err(|e| format!("parsing {}: {e}", index_path.display()))?;

    // Build the font context once and reuse it across every render so the
    // decoded font is cached. MonaSans is a variable font; registering it under
    // one logical family lets `font-weight` select the `wght` axis at render.
    let fonts = load_fonts(fonts_dir)?;

    fs::create_dir_all(output_dir)
        .map_err(|e| format!("creating {}: {e}", output_dir.display()))?;

    let mut count = 0usize;

    // Site-wide default card for the home page (og-image.lua points index at
    // /og/default.png). It shows the site tagline in place of a post title.
    render_card(&fonts, DEFAULT_TAGLINE, &output_dir.join("default.png"))?;
    count += 1;

    for entry in &entries {
        let slug = slug_from_url(&entry.url);
        if slug.is_empty() {
            eprintln!("share-images: skipping entry with unusable url {:?}", entry.url);
            continue;
        }
        render_card(&fonts, &entry.title, &output_dir.join(format!("{slug}.png")))?;
        count += 1;
    }

    Ok(count)
}

/// Render a single card (header + rule + centered title text) to `out_path`.
fn render_card(fonts: &Fonts, title: &str, out_path: &Path) -> Result<(), BoxError> {
    let node = Node::from_html(&card_html(title), FromHtmlOptions::default())?;
    let options = RenderOptions::builder()
        .viewport(Viewport::new((WIDTH, HEIGHT)))
        .node(node)
        .fonts(fonts)
        .build();
    let image = render(options)?;

    let mut file = fs::File::create(out_path)
        .map_err(|e| format!("creating {}: {e}", out_path.display()))?;
    write_image(&image, &mut file, OutputFormat::Png)?;
    Ok(())
}

/// Register the MonaSans variable font under a single logical family. We use
/// the `[wght,opsz]` cut (no width/italic axes) since the cards only need
/// upright weights.
fn load_fonts(fonts_dir: &Path) -> Result<Fonts, BoxError> {
    let font_path = fonts_dir.join("MonaSansVF[wght,opsz].woff2");
    let bytes = fs::read(&font_path)
        .map_err(|e| format!("reading font {}: {e}", font_path.display()))?;

    let mut fonts = Fonts::default();
    fonts.register(FontResource::new(bytes).override_info(FontOverride {
        family_name: Some(FONT_FAMILY.into()),
        ..Default::default()
    }))?;
    Ok(fonts)
}

/// The card markup. A flex column centers the two text blocks; the header sits
/// at the top with a 2px rule beneath it, the title fills the remaining space.
fn card_html(title: &str) -> String {
    format!(
        r#"<div style="
            width: {WIDTH}px;
            height: {HEIGHT}px;
            display: flex;
            flex-direction: column;
            align-items: center;
            background-color: #ffffff;
            font-family: '{FONT_FAMILY}';
            color: #000000;
            padding: 64px;
            box-sizing: border-box;
        ">
          <div style="
            display: flex;
            flex-direction: column;
            align-items: center;
            border-bottom: 2px solid #000000;
            padding-bottom: 24px;
          ">
            <div style="
              font-size: 48px;
              font-weight: 700;
              text-align: center;
            ">{site}</div>
          </div>
          <div style="
            display: flex;
            flex-grow: 1;
            align-items: center;
            justify-content: center;
            width: 100%;
          ">
            <div style="
              font-size: 84px;
              font-weight: 700;
              line-height: 1.1;
              text-align: center;
            ">{title}</div>
          </div>
        </div>"#,
        site = escape_html(SITE_TITLE),
        title = escape_html(title),
    )
}

/// Derive a filename slug from a clean URL like `/session-prep/`.
fn slug_from_url(url: &str) -> String {
    url.trim_matches('/').to_string()
}

fn escape_html(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#39;")
}
