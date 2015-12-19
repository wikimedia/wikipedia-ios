# Utility functions

require 'git'

# Returns true if the `NO_DEPLOY` env var is set to 1
def deploy_disabled?
  ENV['NO_DEPLOY'] == '1'
end

# Returns true if the `NO_TEST` env var is set to 1
def test_disabled?
  ENV['NO_TEST'] == '1'
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

# Parses JSON output of `plutil`
def info_plist_to_hash(path)
  require 'json'
  JSON.parse! %x[plutil -convert json -o - #{path}]
end

