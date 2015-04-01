XCODE_VERSION = "$(shell xcodebuild -version 2>/dev/null)"
XC_WORKSPACE = Wikipedia.xcworkspace
XCODEBUILD_BASE_ARGS = -workspace $(XC_WORKSPACE)
XC_DEFAULT_SCHEME = Wikipedia

help: ##Show this help
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

clean: ##Clean the Xcode workspace
	xcodebuild clean $(XCODEBUILD_BASE_ARGS) -scheme $(XC_DEFAULT_SCHEME) 

build: ##Fetch code dependencies and build the app for release
build: get-deps
	xcodebuild build $(XCODEBUILD_BASE_ARGS) \
		-scheme $(XC_DEFAULT_SCHEME) \
		-sdk iphoneos \
		-configuration Release

build-sim: ##Fetch code dependencies and build the app for debugging in the simulator
build-sim: get-deps
	xcodebuild build $(XCODEBUILD_BASE_ARGS) \
		-scheme $(XC_DEFAULT_SCHEME) \
		-sdk iphonesimulator \
		-configuration Debug

test: ##Fetch code dependencies and run tests
test: get-deps
	xcodebuild test $(XCODEBUILD_BASE_ARGS) \
		-scheme $(XC_DEFAULT_SCHEME) \
		-sdk iphonesimulator

lint: ##Lint the native code, requires uncrustify
	@scripts/uncrustify_all.sh

get-deps: ##Download third-party components (i.e. CocoaPods and npm packages)
get-deps: check-deps pod npm

check-deps: ##Make sure system prerequisites are installed
check-deps: xcode-cltools exec-deps node bundler

#!!!!!
#!!!!! Xcode dependencies
#!!!!!

xcode-cltools: ##Make sure proper Xcode & command line tools are installed
	@case $(XCODE_VERSION) in \
		"Xcode 6"*) echo "Xcode 6 or higher is installed with command line tools!" ;; \
		*) echo "Missing Xcode 6 or higher and/or the command line tools."; exit 1;; \
	esac

#!!!!!
#!!!!! Executable dependencies
#!!!!!

# Append additional dependencies as quoted strings (i.e. EXEC_DEPS = "dep1" "dep2" ...)
EXEC_DEPS = "uncrustify" "convert" "gs"

exec-deps:  ##Check that executable dependencies are installed
	@for dep in $(EXEC_DEPS); do \
		if [[ -x $$(which $${dep}) ]]; then \
			echo "$${dep} is installed!"; \
		else \
			echo "Missing executable $${dep}, please make sure it's installed on your PATH (e.g. via Homebrew)."; \
			exit 1; \
		fi \
	done

#!!!!!
#!!!!! Node dependencies
#!!!!!

NODE_VERSION = "$(shell node -v)"
NPM_VERSION = "$(shell npm -version)"

npm: ##TODO, run npm install

node: # Make sure node is installed
	@if [[ $(NODE_VERSION) > "v0.10" && $(NPM_VERSION) > "1.4" ]]; then \
		echo "node and npm are installed!" ; \
	else \
		echo "Missing node v0.10 and/or higher and npm 1.4 or higher." ; \
		exit 1; \
	fi

#!!!!!
#!!!!! Ruby dependencies
#!!!!!

RUBY_VERSION = "$(shell ruby -v)"
BUNDLER = "$(shell which bundle)"

pod: ##Install native dependencies via CocoaPods
pod: bundle-install
	@$(BUNDLER) exec pod install

bundle-install: ##Install gems using Bundler
bundle-install: bundler
	@$(BUNDLER) config build.nokogiri --use-system-libraries
	@$(BUNDLER) install

bundler: ##Make sure Bundler is installed
bundler: ruby
	@if [[ $(BUNDLER) == "" ]]; then \
		echo "Missing the Bundler Ruby gem." ; \
		exit 1 ; \
	else \
		echo "Bundler is installed!" ; \
	fi

ruby: ##Make sure Ruby is installed
	@if [[ $(RUBY_VERSION) == "" ]]; then \
		echo "Ruby is missing!" ; \
		exit 1 ; \
	else \
		echo "Ruby is installed!" ; \
	fi
