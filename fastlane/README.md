fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
## iOS
### ios analyze
```
fastlane ios analyze
```
Runs linting (and eventually static analysis)
### ios testAndPushBeta
```
fastlane ios testAndPushBeta
```
Runs tests, version, tag, and push to the beta branch
### ios submitAndPushToMaster
```
fastlane ios submitAndPushToMaster
```
Runs tests, version, tag, and push to the beta branch
### ios submitHotfixAndPushToMaster
```
fastlane ios submitHotfixAndPushToMaster
```
Runs tests, version, tag, and push to the beta branch
### ios verifyTestPlatforms
```
fastlane ios verifyTestPlatforms
```
Runs tests on the primary platforms and configurations
### ios verify
```
fastlane ios verify
```
Runs unit tests, optionally generating a JUnit report.
### ios bumpPatch
```
fastlane ios bumpPatch
```
Increment the app version patch
### ios bumpMinor
```
fastlane ios bumpMinor
```
Increment the app version minor
### ios bumpMajor
```
fastlane ios bumpMajor
```
Increment the app version major
### ios bump
```
fastlane ios bump
```
Increment the app's build number without committing the changes. Returns a string of the new, bumped version.
### ios bumpAndTagBeta
```
fastlane ios bumpAndTagBeta
```
Increment the app's beta build number, add a tag, and push to the beta branch.
### ios bumpAndTagRelease
```
fastlane ios bumpAndTagRelease
```
Increment the app's build number, add a tag, and push to the master branch.
### ios tagHotfix
```
fastlane ios tagHotfix
```
Add a tag, and push to the master branch.
### ios default_changelog
```
fastlane ios default_changelog
```
Returns a default changelog.
### ios beta
```
fastlane ios beta
```
Submit a new **Wikipedia Beta** build to Apple TestFlight for internal testing.
### ios store
```
fastlane ios store
```
Submit a new App Store release candidate Apple TestFlight for internal testing.
### ios dev
```
fastlane ios dev
```
Upload a developer build to Hockey.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane/tree/master/fastlane).
