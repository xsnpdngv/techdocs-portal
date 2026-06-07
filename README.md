# TechDocs Portal

A repo-agnostic [TechDocs](https://backstage.io/docs/features/techdocs/techdocs-overview)
documentation portal, packaged as a Docker image. Built on top of
[`mkdocs-techdocs-core`](https://github.com/backstage/mkdocs-techdocs-core)
(the same MkDocs plugin Backstage uses) and extended with:

- **Mermaid** diagrams (client-side, via `mkdocs-mermaid2-plugin`)
- **PlantUML** diagrams (server-side, via the bundled `plantuml_markdown`
  extension and a local `plantuml` binary baked into the image)

Mount any repository that contains an `mkdocs.yml` and the container will
serve its documentation on `http://localhost:8000`.

## Repository layout

| Path                              | Purpose                                                          |
| --------------------------------- | ---------------------------------------------------------------- |
| [`Dockerfile`](Dockerfile)          | Builds the `techdocs-portal` image.                              |
| [`Makefile`](Makefile)              | `make build`, `make serve`, `make build-site`, `make shell`, …   |
| [`techdocs-portal`](techdocs-portal)    | Launcher: serve docs for any `<repo-path>`.                      |
| [`scripts/entrypoint.sh`](scripts/entrypoint.sh) | Container entrypoint (`serve` / `build` / pass-through). |
| [`scripts/plantuml`](scripts/plantuml) | Tiny wrapper that runs `plantuml.jar` from inside the image.  |
| [`overrides/partials/toc.html`](overrides/partials/toc.html) | Material theme override so every `#` heading shows up in the TOC. |
| [`examples/`](examples)             | A ready-to-render sample repo with Mermaid + PlantUML diagrams.  |

## Quick start

```bash
# 1. Build the image
make build

# 2. Serve the bundled example
make serve
# -> open http://localhost:8000

# 3. Serve YOUR repository
./techdocs-portal /path/to/your/repo
# or
make serve REPO=/path/to/your/repo PORT=8001
```

To produce a static site instead of a live server:

```bash
./techdocs-portal -b /path/to/your/repo
# output ends up in /path/to/your/repo/_site
```

## How to augment your repositories

Each repository you want to expose through the portal needs **one
required file** and an optional layout convention.

### 1. `mkdocs.yml` at the repo root (required)

The full annotated example lives at [examples/mkdocs.yml](examples/mkdocs.yml).
Minimum viable version:

```yaml
site_name: My Service Documentation
docs_dir: docs

theme:
  name: material
  # Use the portal's override of `partials/toc.html` so every `#` heading
  # shows up as a top-level chapter in the sidebar TOC instead of being
  # silently dropped by mkdocs-material's default template.
  custom_dir: /opt/techdocs/overrides

plugins:
  - techdocs-core
  - mermaid2

markdown_extensions:
  - toc:
      toc_depth: "1-6"
      permalink: true
      title: On this page
  - plantuml_markdown:
      plantuml_cmd: /usr/local/bin/plantuml
      format: svg
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
          format: !!python/name:mermaid2.fence_mermaid_custom
```

Key points:

- `techdocs-core` brings in the Material theme, all PyMdown extensions
  Backstage relies on, admonitions, the monorepo plugin, and
  `plantuml_markdown`.
- The `plantuml_cmd: /usr/local/bin/plantuml` line points at the local
  binary shipped inside the image, so diagrams render offline.
- The custom `mermaid` fence makes ` ```mermaid ` code blocks render as
  diagrams instead of source code.
- `theme.custom_dir: /opt/techdocs/overrides` pulls in the portal's
  patched `partials/toc.html`. Without it, `mkdocs-material` strips the
  leading H1 from the TOC and silently drops any further H1s on the
  page. With it, every `#` becomes a chapter — see
  [Treating `#` as chapters](#treating--as-chapters) below.

### Treating `#` as chapters

By default, `mkdocs-material` assumes the first `#` heading is the
*page title* (already shown in the header) and drops it from the
right-hand TOC; as a side effect, any later `#` headings on the same
page also disappear. The portal ships an override of
`partials/toc.html` that keeps the full heading tree intact, so a page
like:

```markdown
# Components
...

# Deployment
...
```

renders **Components** and **Deployment** as two top-level entries in
the TOC sidebar. To enable it in your repo:

1. Set `theme.custom_dir: /opt/techdocs/overrides` in your `mkdocs.yml`
   (already done in [examples/mkdocs.yml](examples/mkdocs.yml)).
2. Give each page a title via `nav:` in `mkdocs.yml` **or** YAML front
   matter (`---\ntitle: …\n---`) — otherwise MkDocs falls back to the
   first `#` heading for the page title, which is harmless but means
   you'll see the same text both in the header and at the top of the
   content.

See [examples/docs/architecture/overview.md](examples/docs/architecture/overview.md)
for a working example.

### 2. `docs/` directory (convention)

Put your markdown under `docs/` (or whatever `docs_dir` you configure).
Use any combination of standard markdown, admonitions, Mermaid blocks,
and PlantUML blocks. See:

- [examples/docs/index.md](examples/docs/index.md)
- [examples/docs/architecture/overview.md](examples/docs/architecture/overview.md) — Mermaid
- [examples/docs/architecture/sequences.md](examples/docs/architecture/sequences.md) — PlantUML
- [examples/docs/operations/runbook.md](examples/docs/operations/runbook.md) — admonitions, tables
- [examples/docs/reference/api.md](examples/docs/reference/api.md) — tabbed content

#### Adding whole directories without listing every file

The simplest answer: **omit `nav:` from `mkdocs.yml`**. With no `nav`
key, MkDocs walks the `docs/` tree itself — every subdirectory becomes
a section, every `.md` becomes a page, file names are turned into
titles (`my-page.md` → "My page"), and `index.md` / `README.md` inside
a directory becomes that section's landing page. New files show up
automatically on the next build, with no config changes needed.

```yaml
# mkdocs.yml — no `nav:` key at all
site_name: My Service Documentation
docs_dir: docs
```

Override a page title with a leading `#` heading, or with YAML front
matter:

```markdown
---
title: Custom Page Title
---

# Different on-page heading
...
```

If you want partial control — pin a few entries explicitly and let
MkDocs auto-discover the rest — list the pinned ones in `nav:` and
re-add anything you skip. MkDocs itself does not support a "splice in
everything else" placeholder; for that, install a navigation plugin
like
[`mkdocs-awesome-pages-plugin`](https://github.com/lukasgeiter/mkdocs-awesome-pages-plugin)
yourself (not bundled by default in this image).

> Note: `mkdocs-monorepo-plugin` is bundled by `techdocs-core`. Use it
> when you want to *combine multiple separate MkDocs projects* (each
> with their own `mkdocs.yml`) into one site — it is not the right tool
> for "auto-discover files in this directory".

### 3. `catalog-info.yaml` (optional, for Backstage)

If you ever surface the repo through a real Backstage instance, add
[examples/catalog-info.yaml](examples/catalog-info.yaml). The portal
itself does not consume it.

## Configuration reference

| Variable / flag         | Default                | Meaning                                        |
| ----------------------- | ---------------------- | ---------------------------------------------- |
| `MKDOCS_CONFIG` (env)   | `/docs/mkdocs.yml`     | mkdocs config path inside the container.       |
| `BIND_ADDR` (env)       | `0.0.0.0:8000`         | Bind address for `mkdocs serve`.               |
| `SITE_DIR` (env)        | `/site`                | Output directory for `mkdocs build`.           |
| `PLANTUML_JAVAOPTS` (env) | _(empty)_            | Extra JVM flags for PlantUML (e.g. include path). |
| `make build REPO=…`     | `./examples`           | Repository to mount.                           |
| `make serve PORT=…`     | `8000`                 | Host port to expose.                           |
| `techdocs-portal -i`    | `techdocs-portal:latest` | Image to run.                                |
| `techdocs-portal -b`    | _(off)_                | Build a static site instead of serving.        |

## Notes

- The image is based on `python:3.12-slim-bookworm` and weighs in around
  ~600 MB once Java, Graphviz, and the PlantUML jar are included.
- PlantUML diagrams are rendered at build time (locally), so they work
  offline. Mermaid is rendered in the browser by a CDN-hosted JS bundle,
  so the user's browser needs internet access — switch to
  `mermaid2` with `version` pinned + a local copy if that's a concern.
- For monorepos with several doc trees, enable
  [`mkdocs-monorepo-plugin`](https://github.com/backstage/mkdocs-monorepo-plugin)
  (already installed by `techdocs-core`).
