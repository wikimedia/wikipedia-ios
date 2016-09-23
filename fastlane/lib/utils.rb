# Utility functions

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

# Parses JSON output of `plutil`
def info_plist_to_hash(path)
  require 'json'
  JSON.parse! %x[plutil -convert json -o - #{path}]
end
