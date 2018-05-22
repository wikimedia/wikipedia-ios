.PHONY=build

XCODE_VERSION = "$(shell xcodebuild -version 2>/dev/null)"

help: ##Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

setup: ##Install all required dependencies to build & run the app
	@./scripts/setup

bootstrap: ##Install all required dependencies to build & run the app (alias for setup)
bootstrap: setup

prebuild: ##Install all required dependencies to build & run the app (alias for setup)
prebuild: setup
	
build: ##Build the project
build: setup
	@xcodebuild
	
deps: ##Build deps from scratch. Uses carthage.
	@./scripts/setup force

#!!!!!
#!!!!! Individual executable dependencies (instead of running the all of setup)
#!!!!

get-homebrew: ##Install Homebrew using the bootstrapping script from http://brew.sh
	@./scripts/setup_homebrew

brew-install: ##Install executable dependencies via Homebrew
brew-install:
	@./scripts/brew_install

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

CSS_ORIGIN = $(CSS_PREFIX)/load.php?only=styles&target=mobile&skin=minerva&modules=skins.minerva.base.reset|skins.minerva.content.styles|ext.math.styles|ext.pygments|mobile.app

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

NODE_VERSION = "$(shell node -v 2>/dev/null)"
NPM_VERSION = "$(shell npm -version 2>/dev/null)"

get-grunt: ##Install grunt via Homebrew
get-grunt: brew-install
	brew install grunt

grunt: ##Run grunt
grunt: npm get-grunt
	@cd www && grunt && cd ..

npm: ##Install Javascript dependencies
npm:
	@cd www && npm install && cd ..

get-node: ##Install node via Homebrew
get-node: brew-install
	brew install node

#!!!!!
#!!!!! Ruby dependency management
#!!!!!

RUBY_VERSION = "$(shell ruby -v 2>/dev/null)"
BUNDLER = "$(shell which bundle 2/dev/null)"

get-ruby: ##Install Ruby via rbenv and Homebrew (to remove need for sudo)
	@./scripts/setup_rbenv_and_ruby
	
bundle-install: ##Install all gems using Bundler
bundle-install: bundler-check
	@bundle install

bundler-check: ##Make sure Bundler is installed
bundler-check: ruby-check
	@if ! which -s bundle; then \
		echo "Missing the Bundler Ruby gem." ; \
		exit 1 ; \
	else \
		echo "Bundler is installed!" ; \
	fi

ruby-check: ##Make sure Ruby is installed
	@if [[ $(RUBY_VERSION) == "" ]]; then \
		echo "Ruby is missing!" ; \
		exit 1 ; \
	else \
		echo "Ruby is installed!" ; \
	fi


