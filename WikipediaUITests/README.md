# Records app screenshots for various devices and langs:

- details: https://docs.fastlane.tools/actions/snapshot/
- run the `bundle exec fastlane snapshot` command to kick off the screenshot taking test below
(when debugging `wmf_localizedString:key:` below sometimes I needed to re-run this command before things behaved as expected, probably due to how `SnapshotHelper.swift` interacts with simulators & builds)
- see `/fastlane/snapfile` to configure (langs, simulators, other parameters, etc)


## Steps for capturing new screenshots:
 
- select the "WikipediaUITests" scheme
- open `/fastlane/snapfile` and *temporarily* comment out every lang and simulator but one - ie `EN` and `iPhone 5s`, for example
- run the `bundle exec fastlane snapshot` command once
- i think this lets `SnapshotHelper.swift` configure our build in that simulator? anyway breakpoints set in the `testRecordAppScreenshots()` test below should work as expected after running this once.
- then when you select the `iPhone 5s` simulator (in Xcode) and hit the play button on the `testRecordAppScreenshots()` test below it will behave as expected (ie not fail in unexplainable ways because it's configured for non-EN)
- once the `testRecordAppScreenshots()` test is navigating to the parts of the app you want to record pics, add `snapshot("SomeRelevantString")` where you want pics to be taken (note: no pic will actually be recorded when you're manually running the tests here - that only happens when you run `bundle exec fastlane snapshot`)
- after everthing is working don't forget to turn off breakpoints
- then run `bundle exec fastlane snapshot` - this will record pics for the one lang and sim you chose so you can do a quick proof and ensure all the images are being saved
- re-open `/fastlane/snapfile` and undo the comment you added in the 2nd step above (so snapshots for all sims and langs are recorded)
- run `bundle exec fastlane snapshot` to take snapshots for ALL langs and sims (this can take a while)


## Tips:
 
- setting a breakpoint in the `testRecordAppScreenshots()` test, running it, and using `print(XCUIApplication().debugDescription)` in the console when the breakpoint hits is handy for seeing what buttons/elements we can interact with or tap on the current screen. Find the button with the label string you are looking for (in the tree printed by `print(XCUIApplication().debugDescription)`) then find the key for that label's localized string and use it (this is what enables these tests to work in non-EN langs).
- the Xcode Accessibility Inspector ("Xcode > Open Developer Tool > Accessibility Inspector") is also VERY useful for seeing what accessibility label strings are associated with text-less image buttons.
- `sleep(n)` is also handy for pausing when debugging (this uitest target sleeps - the app doesn't)
- uncheck "main thread checker" https://github.com/fastlane/fastlane/issues/10381#issuecomment-332183767 and https://forums.developer.apple.com/thread/86476
- it appears to not work correctly if you try to have more than one test kick off screenshot recording. weird freezes, etc. so below we just use the single test method: `testRecordAppScreenshots()` for now
- set a breakpoint on a call to `sleep(n)` in location of interest, then `print(XCUIApplication().debugDescription)` to get tree of what's onscreen so you can find button string to use to search for localization key for that string so you can programatically "push" that button
- you can use control-option-command-U to re-run last test you ran!
- remember that when this gets run by fastlane the app is a clean install every time (so we start from the first welcome screen) but when tweaking tests you may have left off after the welcome screens (so you can just temporarily comment out the welcome screen lines below when adding new screenshots). just be sure that when you're done adding new screenshots you test with clean install and that all the steps progress normally - you should be able to watch it progress through the first welcome screen all the way to the last item below - that way you'll know when fastlane does the same thing from a clean install that everything will go smoothly.
- when debugging it can be helpful to watch the screenshots appear in this temp dir: `~/Library/Caches/tools.fastlane/screenshots/`
