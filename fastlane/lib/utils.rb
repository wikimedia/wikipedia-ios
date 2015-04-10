# Utility functions

require 'git'

# Returns true if the `NO_RESET` env var is set to 1
def reset_disabled?
  ENV['NO_RESET'] == '1'
end

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

def run_unit_tests
  xctest({
    scheme: 'Wikipedia',
    destination: "platform=iOS Simulator,name=iPhone 6,OS=8.2",
    report_formats: [ "html", "junit" ],
    report_path: "build/reports/iOS82/report.xml",
    clean: nil
  })
end

# Generate a list of commit subjects from `rev` to `HEAD`
# :rev: The git SHA to start the log from, defaults to `ENV[LAST_SUCCESS_REV']`
def generate_git_commit_log(rev=ENV['LAST_SUCCESS_REV'])
  g = Git.open(Dir.getwd)
  change_log = g.log.between(rev).map { |c| "- " + c.message.lines.first.chomp }.join "\n"
  "Commit Log:\n\n#{change_log}\n"
end

# Memoized version of `generate_git_commit_log` which stores the result in `ENV['GIT_COMMIT_LOG']`.
def git_commit_log
  ENV['GIT_COMMIT_LOG'] || ENV['GIT_COMMIT_LOG'] = generate_git_commit_log
end

def hockey_api_token
  ENV['HOCKEY_API_TOKEN']
end

def deploy_testflight_build
  # Upload the DSYM to Hockey
  hockey({
    api_token: hockey_api_token,
    notes: git_commit_log,
    notify: 0,
    status: 1, #Means do not make available for download
  })

  #Set "What To Test" in iTunes Connect for Testflight builds, in the future, reference tickets instead of git commits
  DELIVER_WHAT_TO_TEST.replace = git_commit_log
  #Set "App Description" in iTunes Connect for Testflight builds, in the future set a better description
  DELIVER_BETA_DESCRIPTION.replace = git_commit_log
  #Set "Feedback email" in iTunes Connect for Testflight builds
  DELIVER_BETA_FEEDBACK_EMAIL.replace = 'abaso@wikimedia.org'

  # Upload the IPA and DSYM to iTunes Connect
  deliver :testflight, :beta, :skip_deploy, :force
end

