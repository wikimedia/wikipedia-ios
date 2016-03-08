# Utility functions

# Returns true if the `NO_DEPLOY` env var is set to 1
def deploy_disabled?
  ENV['NO_DEPLOY'] == '1'
end

# Runs goals from the project's Makefile, this requires going up to the project directory.
# :args: Additional arguments to be passed to `make`.
# Returns The result of the `make` command
def make(args)
  # Maybe we should write an "uncrustify" fastlane action?...
  Dir.chdir '..' do
    sh 'make ' + args
  end
end

# Create a string of the app version & build number
# Must be invoked w/in fastlane
def get_version_string
  "#{get_version_number}.#{get_build_number}"
end

# Create a string of the build number with a "b" to denote beta status
# Must be invoked w/in fastlane
def get_beta_build_number
  number = (get_build_number.to_i + 1)
  "#{number}b"
end

# Create a string of the build number without a "b" for release
# Must be invoked w/in fastlane
def get_release_build_number
  number = get_build_number.chomp("b")
  number
end

# Parses JSON output of `plutil`
def info_plist_to_hash(path)
  require 'json'
  JSON.parse! %x[plutil -convert json -o - #{path}]
end
