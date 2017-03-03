fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

## Choose your installation method:

<table width="100%" >
<tr>
<th width="33%"><a href="http://brew.sh">Homebrew</a></td>
<th width="33%">Installer Script</td>
<th width="33%">Rubygems</td>
</tr>
<tr>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS</td>
<td width="33%" align="center">macOS or Linux with Ruby 2.0.0 or above</td>
</tr>
<tr>
<td width="33%"><code>brew cask install fastlane</code></td>
<td width="33%"><a href="https://download.fastlane.tools/fastlane.zip">Download the zip file</a>. Then double click on the <code>install</code> script (or run it in a terminal window).</td>
<td width="33%"><code>sudo gem install fastlane -NV</code></td>
</tr>
</table>
# Available Actions
## iOS
### ios checkout
```
fastlane ios checkout
```
Checks out the sha specified in the environment variables or the develop branch
### ios analyze
```
fastlane ios analyze
```
Runs linting (and eventually static analysis)
### ios verify_test_platforms
```
fastlane ios verify_test_platforms
```
Runs tests on the primary platforms and configurations
### ios verify_pull_request
```
fastlane ios verify_pull_request
```
Runs tests on select platforms for verifying pull requests
### ios verify
```
fastlane ios verify
```
Runs unit tests, generates JUnit report.
### ios bump_build
```
fastlane ios bump_build
```
Increment the build number
### ios bump_patch
```
fastlane ios bump_patch
```
Increment the app version patch
### ios bump_minor
```
fastlane ios bump_minor
```
Increment the app version minor
### ios bump_major
```
fastlane ios bump_major
```
Increment the app version major
### ios tag
```
fastlane ios tag
```
Add a tag for the current build number and push to repo.
### ios tag_release
```
fastlane ios tag_release
```
Add a tag for the current version number push to repo.
### ios build
```
fastlane ios build
```
Build the app for distibution
### ios push_beta
```
fastlane ios push_beta
```
updates version, builds, and pushes to TestFlight
### ios push_alpha
```
fastlane ios push_alpha
```
updates version, builds, and pushes alpha to TestFlight
### ios push_beta_cluster
```
fastlane ios push_beta_cluster
```
updates version, builds, and pushes beta cluster to TestFlight
### ios get_latest_alpha_or_beta_build_number
```
fastlane ios get_latest_alpha_or_beta_build_number
```

### ios push
```
fastlane ios push
```
updates version, builds, and pushes to TestFlight
### ios test_and_push_beta
```
fastlane ios test_and_push_beta
```
Runs tests, version, tag, and push to the beta branch
### ios submit_release
```
fastlane ios submit_release
```
Runs tests, version, tag, and push to the beta branch
### ios dsyms
```
fastlane ios dsyms
```
Download dSYMs from iTunes Connect and upload them to HockeyApp
### ios dsyms_alpha
```
fastlane ios dsyms_alpha
```

### ios dsyms_beta
```
fastlane ios dsyms_beta
```


----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
