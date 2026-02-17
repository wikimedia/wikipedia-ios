# Wikipedia iOS Architecture Guide

This is an overview of our architecture goals for new feature and refactoring work in the Wikipedia iOS app. This is subject to change and evolve.

## WMFData

WMFData is a local Swift package designed to house all of the logic pertaining to the data layer of the app. Its goals are to implement all of the networking, persistence, and caching for every feature in the app. There are several foundational classes that perform these duties. These are intended to be feature-agnostic.

### Services
`Sources > WMFData > Services`

Services are classes that are capable of making API calls via URLSession. We have two services in our app: WMFBasicService, which is capable of making unauthenticated API calls, as well as our mediaWikiService, which is capable of making authenticated API calls. Both service classes can be accessed via the WMFDataEnvironment.current singleton (located in Sources > WMFData > Environment directory), through the mediaWikiService and basicService properties.

Eventually, we want to combine these into one simple service class, but all of our legacy authentication logic still lives outside of WMFData. So for now we have split them up - any authenticated calls still use the WMFDataEnvironment.current.mediaWikiService interface, but under-the-hood it calls back to the legacy area of the app to lean on it's authentication + url session calls.

### Stores
`Sources > WMFData > Store`

Stores are classes that are capable of persisting data to the app. They can also be accessed via the WMFDataEnvironment.current singleton. Currently we have 3 stores:

1. userDefaultsStore - capable of saving and loading to user defaults
2. sharedCacheStore - capable of saving and loading to the file system (note this calls back to the legacy area of the app, eventually we want to move this wholly into WMFData).

(Note that both userDefaultsStore and sharedCachedStore are accessed via a generalized protocol WMFKeyValueStore)

3. coreDataStore - capable of saving and loading to WMFData's own Core Data xcdatamodel.

Stores and services should be strictly feature-agnostic.

### Data Controllers
`Sources > WMFData > Data Controllers`

On top of stores and services sits a publicly accessible layer of classes called data controllers. These classes are usually feature-specific, but can be shared amongst multiple features as well. Data controllers are simple classes that contain references to the stores and services it needs to interact with all data related to that feature or function. Data controllers are meant to serve as an abstraction layer so that callers do not need to know where a particular piece of data is coming from (that is, remotely or locally). It should only return basic struct or class models to the callers, not Core Data NSManagedObjects.

Sometimes data controllers serve up data that needs to be re-used across multiple features, such as saved article counts. When that occurs, we ensure the data controller is named in a generic manner (i.e. feature-agnostic), and it lives in the relative Shared subdirectory). Feature-specific data controllers then call into the shared data controllers to get their data.

Sometimes data controllers have simple built-in in-memory caching, so that repeated calls to fetch the same data do not trigger repeated network or database calls. In this instance, they will be set up as a singleton, with a .shared property. Ensure all usages of these data controllers lean on {DataController}.shared to avoid multiple instances.

Ideally, public data controller methods use async throws as a method signature.

#### Notable Shared data controllers

There are a couple of shared data controllers are worth noting:

**WMFImageDataController.shared**

Use this singleton to fetch image data in WMFComponents. This data controller performs better than SwiftUI's AsyncImage. You can use them in your SwiftUI views like so:

    final class ExampleViewModel: ObservableObject {
        @Published var uiImage: Data?

        init(imageURL: URL) {
            Task {
                try await loadImage(url: imageURL)
            }
        }
        
       private func loadImage(imageURL: URL) async throws {
            let data = try await WMFImageDataController.shared.fetchImageData(url: imageURL)
            self.uiImage = UIImage(data: data)
        }
    }

    struct ExampleView: View {
        @ObservedObject var viewModel: ExampleViewModel
        
        init (viewModel: ExampleViewModel) {
            self.viewModel = viewModel
        }
        
        var body: some View {
            if let uiImage = viewModel.uiImage {
            }
        }
    }
    
**WMFArticleSummaryDataController.shared**

Use this singleton to fetch summary information in for a particular article. This is often used for fetching an article's description and image thumbnail, which are used in many places throughout the app. One pattern we like to use is fetching an article's summary internally in the granular row's view model upon instantiation. This ensures summary data is only fetched when the row is scrolled on screen in a SwiftUI List. Combined with image data fetching, it could look like this:

    final class ExampleRowViewModel: ObservableObject {
        @Published var description: String?
        @Published var uiImage: Data?
        
        private let title: String
        private let project: WMFProject
        private var thumbnailURL: URL?

        init(title: String, project: WMFProject) {
            self.title = title
            self.project = project
            
            Task {
                try await loadSummary()
                try await loadImage()
            }
        }
        
        private func loadSummary() async throws {
            let summary = try await WMFArticleSummaryDataController.shared.fetchSummary(for: title, in: project)
            self.description = summary.description
            self.thumbnailURL = summary.thumbnailURL
        }
        
        private func loadImage() async throws {
            guard let thumbnailURL else { return }
            let data = try await WMFImageDataController.shared.fetchImageData(url: thumbnailURL)
            self.uiImage = UIImage(data: data)
        }
    }

    struct ExampleRowView: View {
        @ObservedObject var viewModel: ExampleRowViewModel
        
        init (viewModel: ExampleRowViewModel) {
            self.viewModel = viewModel
        }
        
        var body: some View {
            VStack {
                Text(viewModel.title)
                if let description = viewModel.description {
                    Text(viewModel.description)
                }
                
                if let uiImage = viewModel.uiImage {
                    Image(uiImage: uiImage)
                }
            }
        }
    }
    
    struct ExampleListView: View {
    
        let listViewModel: ListViewModel
    
        var body: some View {
            List {
                ForEach(listViewModel.articles) { article in
                    ExampleRowView(viewModel: ExampleRowViewModel(title: article.title, project: article.project))
                }
            }
        }
    }

### Shared Models
`Sources > WMFData > Models > Shared`

The models directory isn't consistently used, we often put feature-specific models as nested definitions in the data controllers themselves. But the Shared directory is important to reference. We often have models that, even if they originate from different backends, need to return the same basic model to the caller of the data controller. In this case it's helpful to lean on shared models so we don't have model explosion.

WMFProject

This is an important enum located in the shared models enum. It represents an app-supported MediaWiki project (such as Wikipedia, Commons, Wikidata, etc). For Wikipedia types, an associated WMFLanguage model value is passed along, which contains both the language code and language variant code (if applicable). With a WMFProject value, WMFData is capable of constructing the correct API urls for that project. In WMFData, avoid using raw urls as article identifiers as much as possible, and instead use WMFProject + (article AKA page) title values. WMFProject has an .id string property to uniquely represent itself in Core Data.

### Environment
`Sources > WMFData > Environment`

- `WMFDataEnvironment.current.serviceEnvironment` - This is an enum of type WMFServiceEnvironment, which is set to either production or staging upon app launch.
- `WMFDataEnvironment.current.appData` - this contains useful global app data in-memory, currently only an array of the app's app languages.

### Extensions
`Sources > WMFData > Extensions`

- `URL+API` - this extension file contains helper methods for creating different API URLs. It takes the current serviceEnvironment into consideration when creating these.
- `DateFormatter+MediaWikiAPI` - this contains date formatters that are useful in converting dates into a readable format for consumption of the backend APIs.
- `ImageUtils`, `WMFURLUtils`, `WMFWikitextUtils` - these are helpful utility classes that we expect to be used often throughout the app. They involve manipulation and parsing of urls and wiki text strings.

### Notifications
`Sources > WMFData > Notifications`

WMFNSNotification - all NSNotifications that need to fire from WMFData are defined here.

### Errors
`Sources > WMFData > Errors`

Errors.swift - If we find that we have a lot of common / duplicate errors to throw, they should be refactored into this file. For specific errors, they are defined as nested enums in the data controllers.

### WMFDataMocks

WMFData produces another library called WMFDataMocks, which holds our mocked classes for unit testing. We eventually also want to use these mocked classes in the app itself, which will trigger when we configure the service environment to a new enum called .mocked. This will be useful for mocked UI tests in the future. But for now WMFDataMocks contains json resources and service / store mock classes for use in unit testing.

### Testing
`Tests > WMFDataTests`

Data Controller, Service, and Store, and Utils classes should be unit tested.

To make data controllers testable, you can either dependency inject mocked services and stores in the init or set the WMFDataEnvironment.current settings before your tests run in the XCTestCase setUp() function:

    override func setUp() async throws {
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages:[
            WMFLanguage(languageCode: "en", languageVariantCode: nil),
            WMFLanguage(languageCode: "es", languageVariantCode: nil)
        ])
        WMFDataEnvironment.current.mediaWikiService = WMFMockWatchlistMediaWikiService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
    }

We do not have a mocked Core Data store specifically. Instead we create an actual instance of WMFCoreDataStore, located in a temporary directory.

    final class WMFArticleTabsDataControllerTests: XCTestCase {
        var store: WMFCoreDataStore?

        override func setUp() async throws {
            let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
            self.store = store
        }
    }

For larger references, WMFArticleTabsDataControllerTests showcases how to test a data controller that leans heavily on Core Data. WMFWatchlistDataControllerTests showcases how to test a data controller that leans heavily on other types of backends (mediawiki service, user defaults, and shared cache stores).

---

## WMFComponents

WMFComponents is another local swift package that holds all of the modern UI components in the iOS app. It has set WMFData as its dependency, so it can freely call public data controller methods to get its data.

WMFComponents contains everything one might need to build a single view in an app. Everything from the most foundational tokens like fonts, colors, and icons, up to more complicated components composed of these tokens like buttons, further up to very feature-specific full screens, which are composed of lots and lots of basic components.

### Base Classes
`Sources > WMFComponents > Base`

- `WMFComponentHostingController` - superclass used for all of our hosting controllers. It primarily hooks up an appEnvironmentDidChange method to be called when the WMFAppEnvironment singleton changes.
- `WMFComponentNavigationController` - navigation controller used for all of our navigation controllers. It contains reusable theming code that leans on the UIAppearance API. All navigation controllers in the app should subclass this class to take advantage of consistent looks and behaviors in our navigation bars. Optionally, UIViewControllers (including UIHostingController subclasses) within these navigation controllers can conform to the UINavigationBarConfiguring protocol and call its configureNavigationBar(titleConfig: WMFNavigationBarTitleConfig ...) default implementation method to configure navigation bar titles and buttons upon view controller appearance. This is preferred over one-off .navigationTitle and .toolbar topBar modifiers in SwiftUI.

### Components
`Sources > WMFComponents > Components`

This directory contains all of our components. They are organized into sub directories by feature name. Shared components live in the Shared subdirectory.

### Environment
`Sources > WMFComponents > Environment`

WMFAppEnvironment - like WMFData's WMFDataEnvironment singleton, WMFAppEnvironment contains in-memory settings that are useful across the feature, currently the app's theme, traitCollection, and articleAndEditorTextSize (this is a distinct text size only used in the article and editor feature).

### Style
`Sources > WMFComponents > Style`

#### Theming

All of our themes and their semantic group color names are defined in WMFTheme.swift. Those in turn reference particular color tokens in WMFColor.

To theme a component:

1. Add an observed object property `@ObservedObject var appEnvironment = WMFAppEnvironment.current` to your SwiftUI view.
2. Add modifiers like so to your UI elements:

    .foregroundColor(Color(uiColor: appEnvironment.theme.text))
    
Our legacy themeing approach (which lives in app-side code Theme.swift, and is used like `theme.colors.primaryText` is deprecated. It will not compile in WMFComponents and should not be used.


#### Fonts

All fonts are defined in WMFFont and should flow through that. We use them like so in this modifier:

    .font(Font(WMFFont.for(.semiboldHeadline)))

There are many fonts to choose from, and this method will automatically take dynamic type size into account. If needed you can pass in a particular traitCollection property with your preferredContentSize to prevent the font from scaling with dynamic type:

    .font(Font(WMFFont.for(.semiboldHeadline, compatibleWith: UITraitCollection(preferredContentSizeCategory: .large))))

#### Icons

We want all icon creation to flow through WMFIcon (for custom icons) and WMFSFSymbolIcon (for SFSymbols). This is so that we have a one-stop-shop to see an overview of every icon used in the app.

    let uiImage = WMFSFSymbolIcon.for(symbol: .chevronForward)

If needed you can pass in a particular WMFFont, to have the symbol take on those font characteristics:

    let uiImage = WMFSFSymbolIcon.for(symbol: .globeAmericas, font: WMFFont.boldCaption1)

### Utilities
`Sources > WMFComponents > Utility`

HTMLUtils is a utility class designed to help you create attributed strings from strings containing html (which are rampant in MediaWiki API responses). This is especially helpful for stripping anchor tags and displaying linked text. To capture linked text taps, you can do something like this in SwiftUI:

    Text(attributedString)
        .environment(\.openURL, OpenURLAction { url in
            // add custom handling with url here (if you don't want it to kick out to Safari by default)
            return .handled
        })

### Extensions
`Sources > WMFComponents > Extensions`

- `DateFormatter+Extensions`
- `NumberFormatter+Extensions`

These extension classes are used to format dates and numbers. Any new formatters should be added to these files instead of a one-off in a feature-specific file.

### Testing
`Tests > WMFComponentsTests`

View models and utility classes should be unit tested.

You can assign the mock classes (or core data store with temporary file location) from WMFDataMocks in the same manner for view model tests.

---

## General Architecture

We build all of our new content in SwiftUI. Our SwiftUI content is wrapped up in UIHostingControllers, and displayed within WMFComponentNavigationControllers.

Our SwiftUI views are almost always designed to operate with a view model, which is passed in upon instantiation. View Models are also defined in WMFComponents. View models in turn can internally call a WMFData's data controller to read / write its data.

### Data Controller vs View Model

When does logic belong in a data controller vs a view model? This is sometimes a gray area, but keep these rules in mind:

1. If logic requires importing UIKit or SwiftUI to work, then it belongs in the view model. We do not want WMFData to import any UI frameworks.
2. If logic feels feature-specific, it should NOT be added to a shared data controller. Shared data controllers should be feature-agnostic. It CAN be added to a feature-specific data controller.

The main goal of a data controller is to serve as a persistance vs. network abstraction layer, so that view models do not inherit Core Data baggage. It is acceptable if the data controller only fetches its needed data, then spits out the raw structure (only converted to simple structs / classes), and the view model does all manipulation beyond that.

All specific navigation calls (navigationController.push, viewController.present, etc.) are done via UIKit, and are handled outside of WMFComponents in Coordinator classes.

---

## App-Side Code

Most of our remaining codebase is considered legacy, and we plan to slowly refactor much of it away into WMFData and WMFComponents. There are two pieces to what we consider "apps-side code":

### WMF Framework

This is a legacy dynamic framework that contains reused code across legacy features and processes. It contains mostly the type of code you would see in WMFData (persistence and networking code), but may also contain some view code that needed to be reused across multiple features (like a view reused in both the app and widget). WMF Framework has set WMFComponents as a dependency.

### App Targets
Wikipedia, Experimental, Staging

Finally, this is the highest-level app-side code. It has set WMF Framework as a dependency. It holds everything else.

### Coordinators

One last pattern that we do intend to keep on the app-side is Coordinators. These classes facilitate the instantiation and navigation of feature flows. Coordinators will live in the App-side code, as a part of the app targets (Wikipedia, Experimental, Staging). Coordinators have a navigationController property that we reference to push or present a new flow onto view UIKit APIs. Let's take a typical example of a WMFComponents feature button, that must display another feature upon tap:

Feature 1 view model code (which lives in WMFComponents) holds closure property like "didTapButton2: () -> Void". It is defined upon view model instantiation. App-side, to present feature 1, there is a Feature1Coordinator class that is created somewhere and started.

    class Feature1Coordinator {
        func start() {
            let didTapButton2: () -> Void = { [weak self] in
                let feature2Coordinator = Feature2Coordinator(navigationController: navigationController)
                feature2Coordinator.start()
            }
            let feature1ViewModel = Feature1ViewModel(didTapButton2: didTapButton2)
            let feature1HostingController = Feature1HostingController(viewModel: feature1ViewModel)
            self?.navigationController.push(feature1HostingController, animated: true)
        }
    }

    class Feature2Coordinator {
        func start() {
            let feature2ViewModel = Feature2ViewModel()
            let feature2HostingController = Feature2HostingController(viewModel: feature2ViewModel)
            self?.navigationController.push(feature2HostingController, animated: true)
        }
    }

    let feature1Coordinator = Feature1Coordinator(navigationController: navigationController)
    feature1Coordinator.start()

This Coordinator pattern allows us to reuse a feature's instantiation and flow logic across multiple features.

---

## Workarounds

Because we haven't moved everything we want over to WMFComponents and WMFData yet, sometimes there are some annoying workarounds that we have to incorporate.

### Authentication
As mentioned earlier, the actual url session calls and authentication management for authenticated calls actually happen within WMF Framework. We work around this by assigning a legacy fetcher class to WMFDataEnvironment.current.mediaWikiService from the app launch sequence. Eventually we want WMFData to handle these in-house.

### Localization
We define our localized strings via a custom function called WMFLocalizedString. There is a custom script that is triggered upon build and translations commits that exports and imports strings in a readable format. Any common WMFLocalizedStrings are defined in CommonStrings.swift. Unfortunately, all of this is defined in the legacy app-side code. For WMFComponents, we assign the resolved strings to a LocalizedStrings nested struct in every WMFComponents view model, and reference that structure internally in WMFComponents. We plan to eventually refactor localizations into a separate Swift package that is set as a dependency on WMFComponents.

### Logging
Similar to strings, our instrumentation logging (which arguably belongs in WMFData) also still lives in the legacy app-side code. To work around this, we create a Logging Delegate protocol that view models own a reference to and call upon impressions and button taps. The app-side (typically Coordinators) then serve as the logging delegate and handle the callbacks. We also sometimes use basic closures on the view model for this, similar to how we trigger button taps back to the app-side.

### Legacy Persistence
Some persistence still lives in the apps-side databases. For feature data that hasn't been migrated over to the WMFData database, we have the WMFData data controller call a closure or delegate method to obtain data from the app-side.

### Article URLs
The legacy app-side code often references articles by their full URL strings. Sometimes we need to translate WMFData's preferred WMFProject + title format to full article urls. To do this, on the app-side (such as in a Coordinator), you can translate like so:

    // WMFProject + title to articleURL
    let siteURL = project.siteURL
    let articleURL = siteURL?.wmf_URL(withTitle: title)
    articleURL.wmf_languageVariantCode = project.wmf_languageVariantCode

    // articleURL to WMFProject + title
    let languageCode = articleURL.wmf_languageCode
    let languageVariantCode = articleURL.wmf_languageVariantCode
    let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
    let title = articleURL.wmf_title

You will also see a legacy enum called WikimediaProject. This is a deprecated enum in favor of WMFProject. It should not be used in new features.

## Build and Test

You can use this command to build the app in Terminal:

WMFData:
```
xcodebuild \
      -scheme WMFData \
      -project Wikipedia.xcodeproj \
       -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
      build | xcbeautify
```

WMFComponents:
```
xcodebuild \
      -scheme WMFData \
      -project Wikipedia.xcodeproj \
       -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
      build | xcbeautify
```


App-side:
```
xcodebuild \
      -scheme Wikipedia \
      -project Wikipedia.xcodeproj \
      -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6' \
      build | xcbeautify
```

To run unit tests, use the same commands but add "test" after xcodebuild, e.g. `xcodebuild test \` Each scheme should run to fully confirm unit tests work (WMFData, WMFComponents, App-side).
