.PHONY: install
install: ## Install the virtual environment with uv and install the pre-commit hooks
	@echo "🚀 Creating virtual environment using uv"
	@uv sync
	@uv run pre-commit install

.PHONY: check
check: ## Run code quality tools.
	@echo "🚀 Checking lock file consistency with 'pyproject.toml': Running uv lock --check"
	@uv lock --check
	@echo "🚀 Linting code: Running pre-commit"
	@uv run pre-commit run -a
	@echo "🚀 Static type checking: Running mypy"
	@uv run mypy
	@echo "🚀 Checking for obsolete dependencies: Running deptry"
	@uv run deptry .

.PHONY: test
test: ## Test the code with pytest
	@echo "🚀 Testing code: Running pytest"
	@uv run pytest --cov --cov-config=pyproject.toml --cov-report=xml

.PHONY: build
build: clean-build ## Build wheel file using uv
	@echo "🚀 Creating wheel file"
	@uv build

.PHONY: clean-build
clean-build: ## clean build artifacts
	@rm -rf dist

.PHONY: publish
publish: ## publish a release to pypi.
	@echo "🚀 Publishing: Dry run."
	@uv publish --dry-run --token $(PYPI_TOKEN)
	@echo "🚀 Publishing."
	@uv publish --token $(PYPI_TOKEN)

.PHONY: build-and-publish
build-and-publish: build publish ## Build and publish.

.PHONY: tag
tag: ## Create an annotated git tag v<version> from pyproject.toml (push with: git push origin v<version>)
	@VERSION=$$(uv version --short) && TAG="v$$VERSION" && \
	if git rev-parse -q --verify "refs/tags/$$TAG" >/dev/null; then \
		echo "❌ Tag $$TAG already exists"; exit 1; \
	fi && \
	if ! git diff --quiet HEAD -- pyproject.toml uv.lock; then \
		echo "❌ pyproject.toml or uv.lock has uncommitted changes; commit the version bump first"; exit 1; \
	fi && \
	git tag -a "$$TAG" -m "Release $$TAG" && \
	echo "🏷️  Created tag $$TAG. Push it with: git push origin $$TAG"

.PHONY: docs-test
docs-test: ## Test if documentation can be built without warnings or errors
	@uv run mkdocs build -s

.PHONY: docs
docs: ## Build and serve the documentation
	@uv run mkdocs serve

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
