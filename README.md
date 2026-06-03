# sild.github.io

Personal Hugo site published through GitHub Pages.

## Setup

```sh
git submodule update --init --recursive
```

Use Hugo extended. The currently generated site was built with Hugo `0.136.2`.

## Local preview

```sh
hugo server -D
```

## Deploy

GitHub Actions deploys the tracked `public/` directory. Regenerate the site,
commit both source and `public/`, then push `main`.

```sh
hugo --cleanDestinationDir
git add .
git commit -m "site: update content"
git push
```
