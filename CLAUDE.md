# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal academic website built with the **al-folio** Jekyll theme. It's a static site generator-based website designed for academics, featuring publications, CV, projects, blog posts, and news sections. The site is deployed to GitHub Pages and automatically rebuilds on every push to master.

## Technology Stack

- **Jekyll 4.x**: Static site generator (Ruby-based)
- **Liquid**: Templating language for layouts and includes
- **SASS/SCSS**: Styling
- **Jekyll Scholar**: Bibliography and publication management
- **JavaScript Libraries**: MathJax, Chart.js, Mermaid, TikZ, Vega-Lite for content rendering
- **Docker**: Optional containerized development environment

## Development Commands

### Local Development

**Using Docker (Recommended):**
```bash
docker compose pull
docker compose up
```
Access at: `http://localhost:8080`

**Using Docker (Slim version, <100MB):**
```bash
docker compose up -f docker-compose-slim.yml
```

**Native Ruby (Legacy):**
```bash
bundle install
pip install jupyter  # Required for Jupyter notebook support
bundle exec jekyll serve --lsi
```
Access at: `http://localhost:4000`

The `--lsi` flag enables Latent Semantic Indexing for better related posts.

### Build for Production

```bash
export JEKYLL_ENV=production
bundle exec jekyll build --lsi
```

Output directory: `_site/`

### CSS Optimization

After building, purge unused CSS:
```bash
npm install -g purgecss
purgecss -c purgecss.config.js
```

### Code Quality

**Format code with Prettier:**
```bash
npm install
npx prettier --write .
```

**Pre-commit hooks:**
The repository uses pre-commit hooks for:
- Trailing whitespace removal
- End-of-file fixing
- YAML validation
- Large file detection

Install hooks: `pre-commit install`

## Architecture and File Structure

### Core Configuration
- **`_config.yml`**: Main site configuration (metadata, collections, plugins, Jekyll Scholar settings)
  - Changes require rebuild to take effect
  - Contains personal info, social links, theme settings, and plugin configuration

### Content Structure

**Collections** (defined in `_config.yml`):
- **`_news/`**: News items displayed on the home page
- **`_projects/`**: Project portfolio items
- **`_posts/`**: Blog posts (must follow `YYYY-MM-DD-title.md` naming)
- **`_pages/`**: Static pages (about, CV, publications, etc.)

**Data Files** (`_data/`):
- `cv.yml`: CV in YAML format (fallback when `assets/json/resume.json` is absent)
- `repositories.yml`: GitHub user/repo data for repositories page
- `coauthors.yml`: Co-author metadata for publication linking

**Bibliography**:
- `_bibliography/papers.bib`: Publications in BibTeX format
- Managed by `jekyll-scholar` plugin
- Author matching configured via `scholar.last_name` and `scholar.first_name` in `_config.yml`

### Theme Customization

**Layouts** (`_layouts/`):
- `about.liquid`: Home page layout
- `post.liquid`: Blog post layout
- `distill.liquid`: Distill.pub-style articles
- `cv.liquid`: CV page rendering
- `bib.liquid`: Publication entry rendering (customize buttons here)

**Includes** (`_includes/`):
- Reusable components (header, footer, news, projects, etc.)
- `news.liquid`: News section on about page
- `cv/`: CV section templates
- `repository/`: GitHub repository widgets
- `resume/`: JSON Resume sections

**Styles** (`_sass/`):
- `_themes.scss`: Theme colors (change `--global-theme-color` variable)
- `_variables.scss`: Color palette definitions
- `_base.scss`, `_layout.scss`, `_cv.scss`, `_distill.scss`: Component styles

### Custom Plugins (`_plugins/`)

Ruby plugins extending Jekyll functionality:
- `cache-bust.rb`: Cache busting for assets
- `external-posts.rb`: Fetch external blog posts (e.g., from Medium)
- `google-scholar-citations.rb`: Fetch Google Scholar citation counts
- `hideCustomBibtex.rb`: Filter internal BibTeX keywords
- `remove-accents.rb`: Normalize accented characters

## Content Management

### Adding Publications

1. Add BibTeX entry to `_bibliography/papers.bib`
2. Supported custom fields: `abstract`, `altmetric`, `arxiv`, `bibtex_show`, `blog`, `code`, `dimensions`, `doi`, `html`, `pdf`, `pmid`, `poster`, `slides`, `supp`, `video`, `website`
3. PDF files go in `assets/pdf/`
4. Author highlighting: Configured via `scholar.last_name` and `scholar.first_name` in `_config.yml`
5. Co-author linking: Add co-authors to `_data/coauthors.yml`

### CV Management

Two methods (JSON takes precedence):
1. **JSON Resume** (preferred): `assets/json/resume.json` following jsonresume.org standard
2. **YAML fallback**: `_data/cv.yml` if JSON is deleted

### Creating Content

**Blog Posts**:
- Add to `_posts/` with format `YYYY-MM-DD-title.md`
- Drafts go in `_drafts/` (won't be published)
- Frontmatter controls layout and features

**Projects**:
- Add to `_projects/` as Markdown files
- Displayed in responsive grid on projects page

**News**:
- Add to `_news/` as Markdown files
- Types: inline (shown on about page) or link (navigates to new page)

**Pages**:
- Add to `_pages/` with appropriate frontmatter layout

## Deployment

### GitHub Pages (Automatic)

The site auto-deploys via GitHub Actions on push to `master`:

1. **Workflow**: `.github/workflows/deploy.yml`
2. **Build process**:
   - Ruby 3.2.2 + Bundler
   - Installs Jupyter
   - Runs `bundle exec jekyll build --lsi`
   - Purges unused CSS with PurgeCSS
   - Deploys to `gh-pages` branch
3. **GitHub Pages Settings**: Must be set to deploy from `gh-pages` branch

### Manual Deployment

Trigger via GitHub Actions UI: Actions → Deploy → Run workflow

### Local Production Build

```bash
export JEKYLL_ENV=production
bundle exec jekyll build --lsi
purgecss -c purgecss.config.js
```

Deploy contents of `_site/` to hosting server.

## Important Notes

### Configuration Dependencies

- `url` and `baseurl` in `_config.yml` control all site links:
  - Personal/org site: `url: https://<username>.github.io`, `baseurl:` (empty)
  - Project site: `url: https://<username>.github.io`, `baseurl: /<repo-name>/`

### Jekyll Scholar Configuration

Publication sorting, grouping, and filtering controlled in `_config.yml`:
```yaml
scholar:
  query: "@*"
  group_by: year
  group_order: descending
```

### Image Processing

- `jekyll-imagemagick` plugin generates responsive WebP images
- Requires ImageMagick installed: `convert -version`
- Configuration in `_config.yml` under `imagemagick:`

### External Posts

Medium posts can be pulled via `external_sources` in `_config.yml`:
```yaml
external_sources:
  - name: medium.com
    rss_url: https://medium.com/@username/feed
```

### Theme Features Toggle

Enable/disable features in `_config.yml`:
- `enable_darkmode`: Light/dark mode toggle
- `enable_math`: MathJax for equations
- `enable_google_analytics`: Analytics integration
- `enable_masonry`: Automatic project card layout
- `enable_medium_zoom`: Image zoom on click

## Common Workflows

### Changing Theme Color

1. Edit `_sass/_themes.scss`
2. Change `--global-theme-color` variable
3. Available colors in `_sass/_variables.scss`

### Adding Custom BibTeX Buttons

1. Add field to BibTeX entry (e.g., `demo = {https://example.com}`)
2. Edit `_layouts/bib.liquid` to add button rendering logic
3. Add filtering to `filtered_bibtex_keywords` in `_config.yml` if internal-only

### Customizing Publication Page

1. Edit `_pages/publications.md` for layout
2. Modify `_layouts/bib.liquid` for entry rendering
3. Adjust Jekyll Scholar settings in `_config.yml`

### Working with Liquid Templates

- Liquid syntax: `{{ variable }}` for output, `{% tag %}` for logic
- Jekyll data: Access via `site.data.<filename>` (e.g., `site.data.cv`)
- Frontmatter: Access via `page.<variable>` in layouts
- Collections: Access via `site.<collection_name>` (e.g., `site.news`)