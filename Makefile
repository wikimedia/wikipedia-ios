.PHONY=build

help: ##Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

setup: ##Install all required dependencies to build & run the app
	@./scripts/setup

#!!!!!
#!!!!! Web dependency management
#!!!!!

web: ##Make web assets
web: css grunt

PROD_CSS_PREFIX="https://en.wikipedia.org/w"
BETA_CSS_PREFIX="https://beta.wmflabs.org/w"
LOCAL_CSS_PREFIX="http://127.0.0.1:8080/w"

# Switch to LOCAL_CSS_PREFIX when testing CSS changes in a local MW instance (in vagrant),
# or to BETA_CSS_PREFIX when testing CSS changes which have been staged to beta but not
# yet deployed to production.
CSS_PREFIX=$(PROD_CSS_PREFIX)
WEB_ASSETS_DIR = "Wikipedia/assets"

CSS_ORIGIN = $(CSS_PREFIX)/load.php?only=styles&target=mobile&skin=minerva&modules=skins.minerva.base.styles|skins.minerva.content.styles|ext.math.styles|ext.pygments|mobile.app

define get_css_module
curl -s -L -o
endef

css: ##Download latest stylesheets
	@echo "Downloading CSS assets from $(CSS_PREFIX)..."; \
	mkdir -p $(WEB_ASSETS_DIR); \
	cd $(WEB_ASSETS_DIR); \
	$(get_css_module) 'styles.css' "$(CSS_ORIGIN)" > /dev/null; \
	$(get_css_module) 'abusefilter.css' "$(CSS_ORIGIN)" > /dev/null; \
	$(get_css_module) 'preview.css' "$(CSS_ORIGIN)" > /dev/null

grunt: ##Run grunt
grunt:
	@cd www && grunt && cd ..

npm: ##Install Javascript dependencies
npm:
	@cd www && rm -rf 'node_modules' && npm install && cd ..


