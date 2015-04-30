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

def run_unit_tests
  return if test_disabled?
  xctest({
    scheme: 'Wikipedia',
    destination: "platform=iOS Simulator,name=iPhone 6,OS=8.3",
    reports: [
      {
        report: "html",
        output: "build/reports/report.html"
      },
      {
        report: "junit",
        output: "build/reports/report.xml"
      }
    ],
    clean: nil
  })
end

# Generate a list of commit subjects from `rev` to `HEAD`
# :rev: The git SHA to start the log from, defaults to `ENV[LAST_SUCCESS_REV']`
def generate_git_commit_log(rev=ENV['GIT_PREVIOUS_SUCCESSFUL_COMMIT'] || 'HEAD^^^^^')
  g = Git.open(ENV['PWD'], :log => Logger.new(STDOUT))
  begin
    change_log = g.log.between(rev).map { |c| "- " + c.message.lines.first.chomp }.join "\n"
    "Commit Log:\n\n#{change_log}\n"
  rescue
    "Unable to parse commit logs"
  end
end

# Memoized version of `generate_git_commit_log` which stores the result in `ENV['GIT_COMMIT_LOG']`.
def git_commit_log
  ENV['GIT_COMMIT_LOG'] || ENV['GIT_COMMIT_LOG'] = generate_git_commit_log
end

# Parses JSON output of `plutil`
def info_plist_to_hash(path)
  require 'json'
  JSON.parse! %x[plutil -convert json -o - #{path}]
end

# Hack to read app version from Info.plist
def get_version_short_string(path)
  plist_hash = info_plist_to_hash path
  plist_hash['CFBundleShortVersionString']
end

def deploy_testflight_build(scheme, config)
  return if deploy_disabled?

  increment_version_number(
    version_number: ENV['WMF_VERSION_NUMBER']
  )

  # use Jenkins build number
  increment_build_number(
    build_number: ENV['BUILD_NUMBER'].to_i
  )

  # Create and sign the IPA (and DSYM)
  ipa({
    scheme: scheme,
    configuration: config, #Prevents fastlane from passing --configuration "Release" - bug?
    clean: true,
    archive: nil,
    # verbose: nil, # this means 'Be Verbose'.
  })

  # Upload the DSYM to Hockey
  hockey({
    notes: '',
    notify: '0', #Means do not notify
    status: '1', #Means do not make available for download
  })

  #Set "What To Test" in iTunes Connect for Testflight builds, in the future, reference tickets instead of git commits
  ENV['DELIVER_WHAT_TO_TEST'] = git_commit_log
  #Set "App Description" in iTunes Connect for Testflight builds, in the future set a better description
  # ENV['DELIVER_BETA_DESCRIPTION'] = git_commit_log

  # Upload the IPA and DSYM to iTunes Connect
  deliver(
    force: true, # Set to true to skip PDF verification
    beta: true, # Upload a new version to TestFlight
    skip_deploy: true, # Set true to not submit app for review (works with both App Store and beta builds)
  )
end

def deploy_appstore_build
  return if deploy_disabled?
  # Create and sign the IPA (and DSYM)
  ipa({
    scheme: ENV['IPA_BUILD_SCHEME'],
    configuration: ENV['IPA_BUILD_CONFIG'], #Prevents fastlane from passing --configuration "Release" - bug?
    clean: true,
    archive: nil,
    # verbose: nil, # this means 'Be Verbose'.
  })

  # Upload the DSYM to Hockey
  hockey({
    notes: '',
    notify: '0', #Means do not notify
    status: '1', #Means do not make available for download
  })

  # Upload the IPA and DSYM to iTunes Connect
  deliver(
    force: true, # Set to true to skip PDF verification
    skip_deploy: true, # Set true to not submit app for review (works with both App Store and beta builds)
  )
end

