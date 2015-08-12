#PiwikTracker iOS SDK

**v3.3.0 Setting custom user-agent header is only possible through the PiwikDispatcher.**

**v3.2.3 Added support for custom user-agent header. Renamed a core data entity property due to name conflict.**

**v3.2.0 Added download tracking feature. Bug fixes.**


The PiwikTracker is an iOS and OSX SDK for sending app analytics to a Piwik server.
 
[Piwik](http://piwik.org) server is a downloadable, Free/Libre (GPLv3 licensed) real time analytics platform.

*A detailed [Getting started guide](https://github.com/piwik/piwik-sdk-ios/wiki/Getting-started-guide) has been added to the Wiki section.*

*A [Google Analytics migration guide](https://github.com/piwik/piwik-sdk-ios/wiki/Google-Analytics-migration-guide) has recently been added to the Wiki section.*

*Check out the full [API documentation](http://piwik.github.io/piwik-sdk-ios/docs/html/index.html).*


[![Build Status](https://travis-ci.org/piwik/piwik-sdk-ios.svg?branch=master)](https://travis-ci.org/piwik/piwik-sdk-ios)

##Getting started

The PiwikTracker is easy to use:
 
1. Create a new website in the Piwik web interface called "My App". Copy the Website ID.
2. Add the PiwikTracker to your project
3. Create and configure the PiwikTracker
4. Add code in your app to track screen views, events, exceptions, goals and more
5. Let the SDK dispatch events to the Piwik server automatically, or dispatch events manually

##I like it, how do I get it?

###CocoaPods

If your project is using CocoaPods, add PiwikTracker as a dependency in your pod file:

    pod 'PiwikTracker'
    -- The NSURLSession class will be used for sending requests to the Piwik server
    
    or
    
    pod 'PiwikTracker/AFNetworking2'
    -- AFNetworking2 framework will be used for sending requests to the Piwik server. AFNetworking will be added as dependency to your project.
    
###Source files

If your project is not using CocoaPods:  
 
1. Clone the repo to your local computer
2. Copy all files from the `PiwikTracker` folder to your Xcode project
3. Add the source files to your build target
4. Add the frameworks and dependencies listed under Requirements to your project

###Requirements

The latest PiwikTracker version uses ARC and support iOS7+ and OSX10.8+. It has been tested with Piwik server 2.8.

* iOS tracker depends on: Core Data, Core Location, Core Graphics and UIKit
* OSX tracker depends on: Core Data, Core Graphics and Cocoa

##Demo project

The workspace contains an iPhone demo app that uses and demonstrates the features available in the SDK.

![Example demo screen shoot](http://piwik.github.io/piwik-sdk-ios/demo_project.png)

If you like to run the demo project, start by cloning the repo and run:
    
    pod install
    
Open the `AppDelegate.m` file and change the Piwik server URL and site credentials:
    
```objective-c
static NSString * const PiwikServerURL = @"http://localhost/path/to/piwik/";
static NSString * const PiwikSiteID = @"2";
```
    
If you do not have access to a Piwik server your can run the tracker in debug mode. Events will be printed to the console instead of sent to the Piwik server:
	
```objective-c
// Print events to the console
[PiwikTracker sharedInstance].debug = YES; 
```    

##API

The Piwik SDK is easy to configure and use:

```objective-c

// Create and configure the tracker in your app delegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {  
  // The website ID is available in Piwik web interface "Settings > Websites"
  [PiwikTracker sharedInstanceWithSiteID:PiwikSiteID baseURL:[NSURL URLWithString:PiwikServerURL]];
  // Any additional configuration goes here
}
		
// Track screen views in your view controllers
- (void)viewDidAppear:(BOOL)animated {
  // Recommendation: track the full hierarchy of the screen, e.g. screen/view1/view2/currentView
  [[PiwikTracker sharedInstance] sendViews:@"view1", @"view2", self.title, nil];
}
	  
// Track custom events when users interacts with the app
[[PiwikTracker sharedInstance] sendEventWithCategory:@"Documentary" action:@"Play" name:@"Thrive" value:@8.0];
	
// Measure exceptions and errors after the app gone live
[[PiwikTracker sharedInstance] sendExceptionWithDescription:@"Ops, got and error" isFatal:NO];

// Track when users interact with various social networks
[[PiwikTracker sharedInstance] sendSocialInteraction:@"Like" target:@"cat.png" forNetwork:@"Facebook"];
	
// Measure the most popular keywords used for different search operations in the app
[[PiwikTracker sharedInstance] sendSearchWithKeyword:@"Galaxy" category:@"Books" numberOfHits:17];

// Track goals and conversion rate
[[PiwikTracker sharedInstance] sendGoalWithID:@"1" revenue:100];

// Track outlinks to external websites and apps
[[PiwikTracker sharedInstance] sendOutlink:@"anotherapp://somwhere/else?origin=myapp"];

// Track downloaded files and content. Will show in a dedicated section in the Piwik Server
[[PiwikTracker sharedInstance] sendDownload:@"htttp://someserver.com/image.png"];

// Track ecommerce transactions
PiwikTransaction *transaction = [PiwikTransaction transactionWithBuilder:^(PiwikTransactionBuilder *builder) {
  builder.identifier =
  [builder addItemWithSku: ... ]
  ...
  }];
[[PiwikTracker sharedInstance] sendTransaction:transaction];

// Track campaigns
campaignURLString = ...
[[PiwikTracker sharedInstance] sendCampaign:(NSString*)campaignURLString;

// Track content impressions and interactions with ads and banners
// Track an impression when the ad is shown
[[PiwikTracker sharedInstance] sendContentImpressionWithName:@"DN" piece:@"dn_image.png" taget:@"http://dn.se"];
// Track an interaction when the user tap on the ad
[[PiwikTracker sharedInstance] sendContentInteractionWithName:@"DN" piece:@"dn_image.png" taget:@"http://dn.se"];

// Set a custom user agent profile in requests sent to the Piwik Server
// This can be used to provide additional information about the users device
id<PiwikDispatcher> dispatcher = [PiwikTracker sharedInstance].dispatcher;
if ([dispatcher respondsToSelector:@selector(setUserAgent:)]) {
  [dispatcher setUserAgent:@"My-User-Agent"];
}
```
	  	
Check out the full [API documentation](http://piwik.github.io/piwik-sdk-ios/docs/html/index.html) for additional methods and details.

A more detailed [Getting started guide](https://github.com/piwik/piwik-sdk-ios/wiki/Getting-started-guide) can be found in the Wiki section.

###User ID

Providing the tracker with a user ID lets you connect data collected from multiple devices and multiple browsers for the same user. 

A user ID is typically a non empty string such as username, email address or UUID that uniquely identify the user. The User ID must be the same for a given user across all her devices and browsers.

```objective-c
[PiwikTracker sharedInstance].userID = @"mattias.levin@gmail.com"
```

If user ID is used, it must be persisted locally by the app and set directly on the tracker each time the app is started. 

If no user ID is used, the SDK will generate, manage and persist a random id for you.

###Ecommerce

Track ecommerce transactions in your app by building a transaction containing one or more items. 

```objective-c
// Build the transaction
PiwikTransaction *transaction = [PiwikTransaction transactionWithBuilder:^(PiwikTransactionBuilder *builder) {
  builder.identifier = ...
  builder.grandTotal = ...
  builder.tax = ...
  builder.shippingCost = ...
  builder.discount = ...
  builder.subTotal = ...
  [builder addItemWithSku:@"SKU123" ... ];  // Item 1
  [builder addItemWithSku:@"SKU987" ... ];  // Item 2  
}];
[ sendTransaction:transaction];  
```
###Campaign tracking

Measure and compare how different campaigns bring traffic to your app, e.g. emails, Facebook ads, banners and other links.

1. Register a custom URL schema in your app info.plist file. 
This is needed to launch your app when tapping on the campaign link
2. Detect app launches coming from your campaign links in the `AppDelegate`

```objective-c
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  // Look for any Piwik campaign keywords
  return [[PiwikTracker sharedInstance] sendCampaign:[url absoluteString]];  
}
```

3. Generate Piwik campaigns urls using the [Piwik URL builder](http://piwik.org/docs/tracking-campaigns-url-builder/)
4. Distribute your urls

The Piwik server will only track a campaign if the event is considered a new session and its more the 30 minutes since the last received event.

More details about Piwik campaign tracking can be found over at [Piwik](http://piwik.org/docs/tracking-campaigns/). Please note that some information is not applicable in an app context.

###Prefixing

By default all events will be prefixed with the name of the event type. This will allow Piwik to group and present events of the same type together in the web interface. 

![Example screenshot](http://piwik.github.io/piwik-sdk-ios/piwik_prefixing.png)

You may choose to disable Prefixing:

```objective-c
// Turn automatic prefixing off
[PiwikTracker sharedInstance].isPrefixingEnabled = NO;
```

###Sessions

A new user session (new visit) is automatically created when the app is launched.  If the app spends more then 120 seconds in the background, a new session will be created when the app enters the foreground. 

You can change the session timeout value by setting the sessionTimeout property. You can manually force a new session start when the next event is sent by setting the sessionStart property:

The SDK will send a notification `PiwikSessionStartNotification` just before a new session event is sent to the Piwik server. Use this event to add visit custom variables. 


```objective-c
// Change the session timeout value to 5 minutes
[PiwikTracker sharedInstance].sessionTimeout = 60 * 5;
    
// Start a new session when the next event is sent
[PiwikTracker sharedInstance].sessionStart = YES;
```    

###Dispatch timer

The tracker will by default dispatch any pending events every 120 seconds.

Set the interval to 0 to dispatch events as soon as they are queued. If a negative value is used the dispatch timer will never run, a manual dispatch must be used:

```objective-c	
// Switch to manual dispatch
[PiwikTracker sharedInstance].dispatchInterval = -1;
	    
// Manual dispatch
[PiwikTracker sharedInstance] dispatch];
```

###Dispatchers

A default dispatcher will be selected and created by the tracker automatically based on the dependencies available at run-time:

1. AFNetworking v2
2. NSURLSession (fallback, will always work)

Developers can set their own dispatcher by implementing the `PiwikDispatcher` protocol and instantiating the tracker with their custom implementation. This can be necessary if the app require special authentication, proxy or other network configuration. Consider inheriting from `AFNetworking2Dispatcher` to minimise the implementation effort. An `AFNetworking1Dispatcher` is provided in the repo for backwards compatibility.

##Change log

* Version 3.1.1 Bug fixes
* Version 3.1.0 adds support for content tracking (ads and banners)
* Version 3.0.0 contains major changes. The auth_token has been removed for security reasons and the api for instantiating the tracker has changed slightly. Several new features has been added - custom events, ecommerce tracking, campaigns and more. This version only works with Piwik 2.8 and up. 
* Version 2.5.2 contains an important fix for supporting the Piwik 2.0 bulk request API. Users still using Piwik 1.X can enable the old bulk request format by following the [instructions above](#bulk-dispatching).
* Version 2.5 contains many new features, including tracking social interaction, exceptions and searches. All events are prefixed according to its type to provide grouping and structure in the Piwik web interface. This would be the preferred behaviour for most developers but it can be turned off if interfering with an existing structure.
* Version 2.0 is a complete rewrite of the PiwikTracker, now based on AFNetworking and supporting CocoaPods. The interface is not backwards compatible, however it should be a small task migrating existing apps.

##License

PiwikTracker is available under the [MIT license](LICENSE.md).
