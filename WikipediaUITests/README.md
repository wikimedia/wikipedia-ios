# Records app screenshots for various devices and langs:

- details: https://docs.fastlane.tools/actions/snapshot/
- run the `bundle exec fastlane snapshot` command to kick off the `testRecordAppScreenshots()` screenshot taking test (when debugging `wmf_localizedString:key:` sometimes I needed to re-run this command before things behaved as expected, probably due to how `SnapshotHelper.swift` interacts with simulators & builds)
- see `/fastlane/snapfile` to configure (langs, simulators, other parameters, etc)
- note that for now all languages in `/fastlane/snapfile` are commented out: Jenkins passes specific languages/devices via arguments:
  ie: `bundle exec fastlane snapshot --skip_open_summary --languages "en,de" --devices "iPhone 5s,iPhone 6"`


## Steps for capturing new screenshots:
 
- select the "WikipediaUITests" scheme
- open `/fastlane/snapfile` and *temporarily* comment out every language and simulator but one - ie `EN` and `iPhone 5s`, for example
- run the `bundle exec fastlane snapshot` command once
- i think this lets `SnapshotHelper.swift` configure our build in that simulator? anyway breakpoints set in the `testRecordAppScreenshots()` test should work as expected after running this once.
- then when you select the `iPhone 5s` simulator (in Xcode) and hit the play button on the `testRecordAppScreenshots()` test it will behave as expected (ie not fail in unexplainable ways because it's configured for non-EN)
- once the `testRecordAppScreenshots()` test is navigating to the parts of the app you want to record pics, add `wmf_snapshot("SomeRelevantString")` where you want pics to be taken
- after everything is working don't forget to turn off breakpoints
- then run `bundle exec fastlane snapshot` - this will record pics for the one language and simulator you chose so you can do a quick proof and ensure all the images are being saved
- re-open `/fastlane/snapfile` and undo the comment you added in the 2nd step above (so the full matrix of snapshots for all simulators and languages are recorded)
- run `bundle exec fastlane snapshot` to take snapshots for ALL languages and simulators (this can take a while)
- when debugging it can be helpful to watch the screenshots appear in this temp dir:
<br>`~/Library/Caches/tools.fastlane/screenshots/`
- after screenshotting has completed images are copied to:<br>`~/wikipedia-ios/WikipediaUITests/Snapshots`)

## Tips:
 
- setting a breakpoint in the `testRecordAppScreenshots()` test, running it, and using `expr print(XCUIApplication().debugDescription)` in the console when the breakpoint hits is handy for seeing what buttons/elements we can interact with or tap on the current screen. Find the button with the label string you are looking for (in the tree printed by `expr print(XCUIApplication().debugDescription)`) then find the key for that label's localized string and use it (this is what enables these tests to work in non-EN languages).
- the Xcode Accessibility Inspector ("Xcode > Open Developer Tool > Accessibility Inspector") is also VERY useful for seeing what accessibility label strings are associated with text-less image buttons.
- `sleep(n)` is also handy for pausing when debugging (this UITest target sleeps - the Wikipedia app itself doesn't)
- uncheck "main thread checker" https://github.com/fastlane/fastlane/issues/10381#issuecomment-332183767 and https://forums.developer.apple.com/thread/86476
- it appears to not work correctly if you try to have more than one test kick off screenshot recording. weird freezes, etc. so we just use the single test method: `testRecordAppScreenshots()` for now
- set a breakpoint on a call to `sleep(n)` in location of interest, then `expr print(XCUIApplication().debugDescription)` to get tree of what's onscreen so you can find button string to use to search for localization key for that string so you can programmatically "push" that button
- you can use control-option-command-U to re-run last test you ran! this is extremely handy when debugging.
- remember that when this gets run by fastlane the app is a clean install every time (so we start from the first welcome screen) but when tweaking tests you may have left off after the welcome screens (so you can just temporarily comment out the welcome screen specific screenshotting and/or other bits when adding new screenshotting code). just be sure that when you're done adding new screenshots you test with clean install and that all the steps still execute sequentially from a fresh install - you should be able to watch it progress through the first welcome screen all the way to the end of the screenshotting code - that way you'll know when fastlane does the same thing from a clean install that everything will go smoothly.

