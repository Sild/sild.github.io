+++
title = 'Minimal Hugo workflow for this site'
date = 2022-12-06T19:32:50+01:00
draft = false
type = 'posts'
aliases = ['/posts/how_to_build_it/']
tags = ['dev', 'ops']
+++

This site uses [Hugo](https://gohugo.io/): a static site generator that turns
Markdown content, templates, theme files, and configuration into plain HTML,
CSS, XML feeds, and other files. There is no runtime application server in
production. The generated `public/` directory is the deploy artifact.

The setup has four moving parts:

```text
hugo.toml       site configuration, menus, theme, pagination
content/        Markdown pages and posts
layouts/        local template overrides
static/         files copied as-is, including custom CSS
public/         generated site committed for GitHub Pages
```

## Install Hugo

Use Hugo extended. On macOS with Homebrew:

```sh
brew install hugo
hugo version
```

On Linux, use the package manager if it has a recent enough Hugo:

```sh
sudo apt update
sudo apt install hugo
hugo version
```

If the distribution package is old, install from the official release archive or
use Homebrew on Linux:

```sh
brew install hugo
hugo version
```

On Windows, the usual package-manager path is:

```powershell
winget install Hugo.Hugo.Extended
hugo version
```

The generated version for this site has been built with Hugo `0.136.2`, so a
newer extended Hugo release should be fine. If output changes unexpectedly, check
the Hugo version first:

```sh
hugo version
git diff -- public
```

## Clone and prepare the theme

This repository uses a Hugo theme as a Git submodule. After cloning, initialize
submodules before running the site:

```sh
git submodule update --init --recursive
```

The theme lives under `themes/`, but local changes should go into `layouts/` or
`static/css/site.css`. Editing the submodule directly makes future theme updates
harder to reason about.

## Run the local server

Start Hugo from the repository root:

```sh
hugo server -D --bind 127.0.0.1 --port 1313
```

Open:

```text
http://127.0.0.1:1313/
```

For a clean preview that does not write generated files to `public/`, use
in-memory rendering:

```sh
hugo server -D --bind 127.0.0.1 --port 1313 --disableFastRender --renderToMemory
```

Useful pages to check after content changes:

```text
/
/me/
/it/
/it/page/2/
/it/page/3/
/tags/
```

## Create and edit a post

IT posts live under `content/it/`. Create a file and set frontmatter explicitly:

```sh
hugo new it/my_note.md
vim content/it/my_note.md
```

Example frontmatter:

```toml
+++
title = 'Short technical title'
date = 2026-01-15T20:00:00+01:00
type = 'posts'
tags = ['dev', 'ops']
+++
```

For this site, keep tags scoped:

```text
dev
ops
crypto
search
leadership
```

The post body should be useful without context from chat: explain the problem,
show commands or data shapes, link public references where useful, and keep
company-private details out.

## Build the deploy artifact

GitHub Pages deploys the tracked `public/` directory, so source and generated
output must be committed together.

Build from the repository root:

```sh
hugo --cleanDestinationDir
```

This removes stale generated files before writing the current site. After Hugo
finishes, normalize generated whitespace so `git diff --check` remains clean:

```sh
find public -type f \( -name '*.html' -o -name '*.xml' \) -print0 \
  | xargs -0 perl -pi -e 's/[ \t]+$//'
```

## Check the result

Check source and generated diffs:

```sh
git status --short
git diff -- content layouts static hugo.toml
git diff -- public
```

Check for whitespace errors:

```sh
git diff --check
```

Check post counts and pagination:

```sh
find content/it -maxdepth 1 -type f -name '*.md' ! -name '_index.md' | wc -l
grep -c 'span class="post-title"' public/it/index.html
grep -c 'span class="post-title"' public/it/page/2/index.html
grep -c 'span class="post-title"' public/it/page/3/index.html
```

Check important routes with `wget`:

```sh
for route in / /me/ /it/ /it/page/2/ /it/page/3/ /tags/; do
  wget -q -O /tmp/site-check.html "http://127.0.0.1:1313${route}" \
    && printf '200 %s\n' "$route"
done
```

If the server is not running, check the generated files directly:

```sh
test -f public/index.html
test -f public/it/index.html
test -f public/tags/index.html
```

## Commit

Stage source and generated output together:

```sh
git add content layouts static public hugo.toml README.md
git status --short
git commit -m "site: update content"
```

The deployment rule is simple: if GitHub Pages uploads `public/`, every content
change needs a matching Hugo build before the commit.

References:

* [Hugo installation docs](https://gohugo.io/installation/);
* [Hugo quick start](https://gohugo.io/getting-started/quick-start/);
* [Homebrew Hugo formula](https://formulae.brew.sh/formula/hugo.html).
