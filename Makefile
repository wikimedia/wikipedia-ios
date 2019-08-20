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

PROD_CSS_PREFIX="https://meta.wikimedia.org/api/rest_v1"
LOCAL_CSS_PREFIX="http://localhost:6927/meta.wikipedia.org/v1"

CSS_PREFIX=$(PROD_CSS_PREFIX)
WEB_ASSETS_DIR = "Wikipedia/assets"

CSS_ORIGIN = $(CSS_PREFIX)/data/css/mobile/base

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


