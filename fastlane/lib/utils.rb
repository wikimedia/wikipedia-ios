# Utility functions

# Returns true if the `NO_DEPLOY` env var is set to 1
def deploy_disabled?
  ENV['NO_DEPLOY'] == '1'
end

# Runs goals from the project's Makefile, this requires going up to the project directory.
# :args: Additional arguments to be passed to `make`.
# Returns The result of the `make` command
def make(args)
  Dir.chdir '..' do
    sh 'make ' + args
  end
end

# Create a string of the app version & build number suitable for badging
# Must be invoked w/in fastlane
def get_badge_version_string
  "#{get_version_number}-#{get_build_number}-blue"
end

# Create a string of the app version & build number
# Must be invoked w/in fastlane
def get_version_string
  "#{get_version_number}.#{get_build_number}"
end

# Create a string of the build number for release
# This adds a .1 to differentiate from the beta build number
# Its a bit of a hack, but we cant use "b" to denote a beta (Testflight hates that)
# Also test flight won't allow us to upload more than 1 build with the same build number
# Must be invoked w/in fastlane
def get_release_build_number
  number = "#{get_build_number}.1"
  number
end

# Parses JSON output of `plutil`
def info_plist_to_hash(path)
  require 'json'
  JSON.parse! %x[plutil -convert json -o - #{path}]
end
