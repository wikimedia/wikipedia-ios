## UITests

### Tech stack
Tests written with XCTest framework and Swift programming language. 
(XCTest is Apple's own framework for unit and ui tests which has more deep integration and functionality with applications for Apple platforms than other frameworks. That’s why it is one of the best solution for creating UI Tests for iOS/iPadOS/MacOS applications)

For tests design used **Page Object Model** design pattern

### Test environment
- Tests verified on target: Simulator iPhone 14 Pro iOS 16

### Tests infrastructure
- Created Page Object Model (WikipediaUITests/Sources/Screens/)
- Added support files (WikipediaUITests/Sources)
- Added accessibility identifiers for App elements, but not for all(this takes too much time, so temporary for some elements used they labels)

### Exist tests
```testArticleSearch```
- Search articles with title "Apollo 11"
- Open one of the articles from search results
- Validate that article content is correct
Where to find the test: WikipediaUITests/Sources/Tests/Search/SearchTests.swift

```SnapshotRecorderTests```
- Preset tests from Wikipedia developers. 
Details: see `README.md` in same folder WikipediaUITests/Sources/Tests/SnapshotRecorder
