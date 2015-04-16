# Utility functions

require 'git'

ENV['HOCKEY_API_TOKEN'] = 'c881c19fd8d0401682c4640b7948ef5e'

# Returns true if the `NO_RESET` env var is set to 1
def reset_disabled?
  ENV['NO_RESET'] == '1'
end

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

  unless test_disabled?
    xctest({
      scheme: 'Wikipedia',
      destination: "platform=iOS Simulator,name=iPhone 6,OS=8.3",
      reports: [{
        report: "html",
        output: "build/reports/report.html"
      },
      {
        report: "junit",
        output: "build/reports/report.xml"
        }],
        clean: nil
        })

      end
end

# Generate a list of commit subjects from `rev` to `HEAD`
# :rev: The git SHA to start the log from, defaults to `ENV[LAST_SUCCESS_REV']`
def generate_git_commit_log(rev=ENV['GIT_PREVIOUS_SUCCESSFUL_COMMIT'])
  g = Git.open(ENV['PWD'], :log => Logger.new(STDOUT))
  change_log = g.log.between(rev).map { |c| "- " + c.message.lines.first.chomp }.join "\n"
  "Commit Log:\n\n#{change_log}\n"
  p change_log
end

# Memoized version of `generate_git_commit_log` which stores the result in `ENV['GIT_COMMIT_LOG']`.
def git_commit_log
  ENV['GIT_COMMIT_LOG'] || ENV['GIT_COMMIT_LOG'] = generate_git_commit_log
end

def deploy_testflight_build
  unless deploy_disabled?
    # Upload the DSYM to Hockey
    hockey({
      api_token: ENV['HOCKEY_API_TOKEN'],
      notes: '',
      notify: 0,
      status: 1, #Means do not make available for download
    })

    #Set "Feedback email" in iTunes Connect for Testflight builds
    self.class.const_set("DELIVER_BETA_FEEDBACK_EMAIL", 'abaso@wikimedia.org')
    #Set "What To Test" in iTunes Connect for Testflight builds, in the future, reference tickets instead of git commits
    self.class.const_set("DELIVER_WHAT_TO_TEST", git_commit_log)
    #Set "App Description" in iTunes Connect for Testflight builds, in the future set a better description
    self.class.const_set("DELIVER_BETA_DESCRIPTION", git_commit_log)

    # Upload the IPA and DSYM to iTunes Connect
    deliver :testflight, :beta, :skip_deploy, :force
  end
end
