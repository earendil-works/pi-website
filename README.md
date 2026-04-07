# pi.dev

Website for [pi](https://github.com/badlogic/pi-mono), a terminal-based coding agent by [Earendil](https://earendil.com).

## Prerequisites

Install [blargh](https://github.com/badlogic/blargh) (static site generator):

```bash
npm install -g @mariozechner/blargh
```

## Development

Start the local dev server with live reload:

```bash
./dev.sh
```

Open http://127.0.0.1:8080

The site has two pages:

- http://127.0.0.1:8080 (landing page)
- http://127.0.0.1:8080/packages.html (package gallery)

In dev mode you must use `packages.html` (not `/packages`). In production Caddy rewrites the URL.

Edit files in `src/`. Changes are picked up automatically.

### Structure

```
src/
  index.html          Main landing page
  packages.html       Package gallery
  _partials/          Shared HTML (header, footer)
  _css/               Stylesheets (custom.css has all site styles)
  meta.json           Site title, description, URL
  logo.svg            Pi logo (white, for dark backgrounds)
  favicon.svg         Pi logo with dark background (for browser tabs)
  earendil-logo.svg   Earendil logo
  demo.cast           Asciinema terminal recording
```

## Deployment

```bash
./publish.sh
```

Builds the site into `html/`, rsyncs to the server, and restarts the Caddy container.
