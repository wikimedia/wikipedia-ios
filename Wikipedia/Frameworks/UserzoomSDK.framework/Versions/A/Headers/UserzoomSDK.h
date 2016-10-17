#import <Foundation/Foundation.h>
#import "UZTypedefs.h"
#import "UZDelegate.h"

#define UZ_TAG @""

@interface UserzoomSDK : NSObject

/**
 *  Retrieve the current version of the UserZoom SDK
 *
 *  @return String containing a "x.y.z.y" format version
 */
+ (NSString *)currentVersion;

/**
 *  Initialize the UserzoomSDK with the given tag.
 *
 *  If the study is configured to be shown at 'Start APP', this method
 *  will also start the study.
 *
 *  Usage Example:
 *  didFinishLaunchingWithOptions -> [UserzoomSDK initWithTag:@"QzRUNjAg"];
 *
 *  @param tag of the study (ex. @"QzRUNjAg")
 */
+ (void)initWithTag:(NSString *)tag;

/**
 *  Initialize the UserzoomSDK with the given tag, and the launch options
 *
 *  @param tag of the study (ex. @"QzRUNjAg")
 *  @param launchOptions
 */
+ (void)initWithTag:(NSString *)tag options:(NSDictionary *)launchOptions;

/**
 *  It processes the launchOptions of the AppDelegate, defines if the
 *  applications start from a notification and, if so, if the notification
 *  comes from UserZoom.
 *
 *  @param launchOptions
 *
 *  @return BOOL
 */
+ (BOOL)processLaunchOptions:(NSDictionary *)launchOptions;

/**
 *  Tracks custom events.
 *
 *  Usage Example:
 *
 *  [UserzoomSDK sendEvent:@"TAG1" tag2:@"TAG2" tag3:@"TAG3"];
 *
 *  @param tag1 @"CustomEventParameter 1"
 *  @param tag2 @"CustomEventParameter 2"
 *  @param tag3 @"CustomEventParameter 3"
 */
+ (void)sendEvent:(NSString *)tag1 tag2:(NSString *)tag2 tag3:(NSString *)tag3;

/**
 *  Send information of the search keywords
 *
 *  @param keywords Strings with the search
 */
+ (void)sendKeywords:(NSString *)keywords;

/**
 *  Enables/disables view recording.
 *
 *  Usage Example:
 *  On viewDidAppear    -> [UserzoomSDK blockRecord:YES];
 *  On viewDidDisappear -> [UserzoomSDK blockRecord:NO];
 *
 *  @param value YES (disable recording) or NO (enable recording)
 */
+ (void)blockRecord:(BOOL)value;

/**
 *  Starts the study initialized with initWithTag:(NSString*) if it is configured
 *  to be shown as 'Customized'. If it is configured as 'Start APP', this method
 *  does nothing
 */
+ (void)show;

/**
 *  Starts a study with a different tags than the initialized one
 *
 *  @param tag of the new study to be started
 */
+ (void)show:(NSString *)tag;

/**
 *  Finalizes the current study
 *
 *  Usage Example:
 *  On viewDidAppear    -> [UserzoomSDK finalizeStudy];
 */
+ (void)finalizeStudy;

/**
 *  Sets the Debug level of the SDK:
 *
 *  - SILENT: Does not LOG anything.
 *  - INFO: Logs basic information
 *  - WARNING: Logs basic information and some warnings
 *  - ERROR: Logs basic information, some warnings and errors. Errors are also sent to the server.
 *  - VERBOSE:  Logs everything. Errors are also sent to the server.
 *
 *  @warning Remember to set debug level to SILENT for release (is the default one)
 *
 *  @param level The desirev level
 */
+ (void)setDebugLevel:(UZLogLevel)level;

/**
 *  Resumes the study flow after returning from a local notification
 */
+ (void)continueFlow:(UILocalNotification *)notification;

/**
 *  Lets the SDK know that local notification permissions have been changed
 */
+ (void)changePermissions:(UIUserNotificationSettings *)settings;

/**
 *  Starts study using an invitation
 *
 *  mimic the openURL:sourceApplication:annotation method of UIApplicationDelegate
 *  to execute the init of the study when the url is valid.
 *
 *  @param url               url from the appdelegate
 *  @param sourceApplication sourceApplication from appdelegate
 *  @param annotation        annotation from appdelegate
 *
 *  @return true if the url is valid for start a userzoom study
 */
+ (BOOL)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

/**
 * To enable the Exit Survey mode.
 *
 *  By enabling the Exit Survey mode an Exit Alert displays when users leave the app and,
 *  once the alert is accepted, the study begins.
 */
+ (void)useExitSurvey;

/**
 *  Sets development mode
 *
 *  Allows a developer to skip checks and show the intercept always.
 *
 *  WARNING: This is intended for testing purposes only, do not release an application calling this method
 */
+ (void)setDevelopmentMode;

/**
 * Clear UserZoom expiration data stored in the App.
 */
+ (void)clearExpirationData;

/**
 * Developer callbacks for the current state of the study
 */
+ (void)setDeveloperCallback:(id<UZDelegate>)delegate;

/**
 * Activate the invitation exclusive mode, where the app will close unless the sdk is started from 
 * an invitation link
 */
+ (void)deactivateAppAfterStudy:(NSDictionary *)launchOptions;

/**
 * Activate the invitation exclusive mode, where the app will close unless the sdk is started from 
 * an invitation link, specifying the alert's message and button text
 */
+ (void)deactivateAppAfterStudyWithMessage:(NSString *)message andButtonText:(NSString *)buttonText andOptions:(NSDictionary *)launchOptions;
@end
