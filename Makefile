# ---------------------------------------------------------------------------
# TechDocs portal — build & run helpers
# ---------------------------------------------------------------------------
IMAGE        ?= techdocs-portal
TAG          ?= latest
IMAGE_FULL   := $(IMAGE):$(TAG)

# Repository to render. Override with: make serve REPO=/path/to/repo
REPO         ?= $(CURDIR)/examples
PORT         ?= 8000

# Pin upstream versions here; passed as build args to Docker.
TECHDOCS_CORE_VERSION ?= 1.6.2
MERMAID2_VERSION      ?= 1.2.1
PLANTUML_VERSION      ?= 1.2024.7

DOCKER       ?= docker

.PHONY: help build rebuild serve build-site shell clean clean-image

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*##"; printf "Targets:\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

build: ## Build the techdocs-portal Docker image.
	$(DOCKER) build \
		--build-arg TECHDOCS_CORE_VERSION=$(TECHDOCS_CORE_VERSION) \
		--build-arg MERMAID2_VERSION=$(MERMAID2_VERSION) \
		--build-arg PLANTUML_VERSION=$(PLANTUML_VERSION) \
		-t $(IMAGE_FULL) .

rebuild: ## Rebuild the image from scratch (no cache).
	$(DOCKER) build --no-cache \
		--build-arg TECHDOCS_CORE_VERSION=$(TECHDOCS_CORE_VERSION) \
		--build-arg MERMAID2_VERSION=$(MERMAID2_VERSION) \
		--build-arg PLANTUML_VERSION=$(PLANTUML_VERSION) \
		-t $(IMAGE_FULL) .

serve: ## Run the portal against REPO=<path> (defaults to ./examples).
	./techdocs-portal -i $(IMAGE_FULL) -p $(PORT) $(REPO)

build-site: ## Render a static site from REPO into ./_site.
	mkdir -p $(CURDIR)/_site
	$(DOCKER) run --rm \
		-v "$(REPO)":/docs:ro \
		-v "$(CURDIR)/_site":/site \
		$(IMAGE_FULL) build

shell: ## Open a shell inside the image (REPO mounted at /docs).
	$(DOCKER) run --rm -it \
		-v "$(REPO)":/docs \
		--entrypoint /bin/bash \
		$(IMAGE_FULL)

clean: ## Remove the local _site/ output.
	rm -rf $(CURDIR)/_site

clean-image: ## Remove the local Docker image.
	-$(DOCKER) rmi $(IMAGE_FULL)
