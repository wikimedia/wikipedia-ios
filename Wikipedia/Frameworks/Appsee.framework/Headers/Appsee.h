//
//  Appsee.h
//  Appsee v2.3.1
//
//  Copyright (c) 2016 Shift 6 Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <SystemConfiguration/SystemConfiguration.h>

@protocol AppseeDelegate;

/********************************************************************************************
    Appsee SDK.
    To use, simply call 'start:' in your 'applicationDidFinishLaunching:withOptions:' method. 
 *******************************************************************************************/

@interface Appsee: NSObject

/***************
 General Control
 **************/

/** Starts recording screen and user gestures. This method should only be called once.
    Recording will stop (and video will be uploaded) when app is in the background.
    A new session will start when the app is returned from background.
 @param apiKey The application-specific API key from (available in your Appsee dashboard).
 */
+(void)start:(NSString*) apiKey;

/** Stops the current video (session tracking will continue). Usually, this method shouldn't be called unless you explictly want to stop video recording.  
 */
+(void)stop;

/** Stops the current session and uploads it immediately (in the background). Usually, this method shouldn't be called unless you explictly want 
    to stop recording and force uploading at some point in your app, before the user minimizes it.
 */
+(void)stopAndUpload __deprecated_msg("Please use [finishSession:NO upload:YES] instead");

/**
 * Finishes the current session and uploads it (in the background). Usually, this method shouldn't be called unless you
 * explicitly want to stop recording and force uploading at some point in your app, before the user minimizes it.
 @param verifyBackground Finish the session only if app is in background (pass 'NO' unless you have a Voip app).
 @param shouldUpload Upload the session immediately, or wait until the app is in the background.
 */
+(void)finishSession:(BOOL)verifyBackground upload:(BOOL)shouldUpload;

/**
 * Upload previous sessions. This method should not be called unless your app is never in the background and you want to upload 
 * sessions on the foreground.
 */
+(void)upload;

/**
 * Force Appsee to start a new session (if not already running). Applicable only when a prior session was manually finished using finishSession:upload:
 */
+(void)forceNewSession;

/**
 * Pause recording of the video. To resume, call 'resume'.
 */
+(void)pause;

/** Resume recording of the video.
 */
+(void)resume;

/** Enable Appsee event-logging to NSLog.
 @param log YES to turn on debug logging, NO to turn them off.
 */
+(void)setDebugToNSLog:(BOOL)log;

/** Set whether to opt-out of using Appsee in the current device (default is false).
* @param isOptOut YES to opt-out current device, NO to opt-in.
*/
+(void)setOptOutStatus:(BOOL)isOptOut;

/** Get the opt-out status of the current device.
* By default, devices are opted-in, meaning this method would return false.
* @return a boolean value stating whether current device is opted-out.
*/
+(BOOL)getOptOutStatus;

/****************************
 Application Events & Screens
 ***************************/

/** Add a timed application event (such as: user reached a specific level or screen).
 @param eventName The name of the event (ie: "WelcomeScreen").
 */
+(void)addEvent:(NSString*)eventName;

/** Add a timed application event (such as: user reached a specific level or screen) along with custom properties.
 @param eventName The name of the event (ie: "Level").
 @param properties Key-value pairs with custom properties for the event. Properties must be NSNumbers, NSStrings, NSDates, NSURL, or NSNull. Keys must be NSStrings.
 */
+(void)addEvent:(NSString*)eventName withProperties:(NSDictionary *)properties;

/** Mark the appearance starting time of a screen.
 This method should be usually called from the viewDidAppear: method.
 @param screenName The name of the screen (ie: "WelcomeScreen").
 */
+(void)startScreen:(NSString*)screenName;

/** Overlay an image on top of the next video frame.
 @param image The image to overlay. Can be 'nil' to stop overlaying any image.
 @param rect The image's location in the screen.
 */
+(void)overlayImage:(UIImage*)image inRect:(CGRect)rect;

/************************
 Setting User Information
 ************************/
 
/** Set the app's user ID. 
 @param userID The application-specific user identifier.
 */
+(void)setUserID:(NSString*)userID;

/** Set the user's location. 
 @param latitude Latitude.
 @param longitude Longitude.
 @param horizontalAccuracy Horizontal Accuracy.
 @param verticalAccuracy Vertical Accuracy.
 */
+(void)setLocation:(double)latitude longitude:(double)longitude horizontalAccuracy:(float)horizontalAccuracy verticalAccuracy:(float)verticalAccuracy;

/** Set the user's location.
 @param description The location's description.
*/
+(void)setLocationDescription:(NSString*)description;

/****************
 Privacy Control
 ****************/
 
/** Mark a view as sensitive, to ensure it is not displayed in videos.
 @param view A UIView that contains sensitive information.
 */
+(void)markViewAsSensitive:(UIView*)view;

/** Mark a layer as sensitive, to ensure it is not displayed in videos.
 @param layer A CALayer that contains sensitive information.
 @param view the UIView which contains the sensitive layer.
 */
+(void)markLayerAsSensitive:(CALayer*)layer inView:(UIView *)parentView;

/** Unmark a view as sensitive, so it will be displayed in videos. Unmarking a view will also prevent future auto-detected views from being masked.
 @param view A UIView that no longer contains sensitive information.
 */
+(void)unmarkViewAsSensitive:(UIView*)view;

/** Unmark a layer as sensitive, so it will be displayed in videos.
 @param layer A CALayer that no longer contains sensitive information.
 @param view the UIView which contains the layer.
 */
+(void)unmarkLayerAsSensitive:(CALayer *)layer inView:(UIView *)parentView;

/*********************
3rd Party Integration
**********************/ 
/** Generate a unique ID for an external 3rd party system.
This method should be usually called right after the start: method.
@param systemName The 3rd party system name (ie: "Adobe")
@param isPersistent Whether the identifier should be persistent across sessions.
*/
+(NSString *)generate3rdPartyID:(NSString *)systemName persistent:(BOOL)isPersistent;

/** Set the ID of an external 3rd party system.
This method should be usually called right after the start: method.
@param systemName The 3rd party system name (ie: "Adobe")
@param isPersistent Whether the identifier should be persistent across sessions.
*/
+(void)set3rdPartyID:(NSString *)externalID forSystem:(NSString *)systemName persistent:(BOOL)isPersistent;

/*********
 Delegate
 *********/
/** Set a delegate to receive appsee notifications
 * @param delegate an instance of AppseeDelegate
 */
+(void)setDelegate:(id<AppseeDelegate>)delegate;
@end


/************************
 AppseeDelegate Protocol
************************/
@protocol AppseeDelegate <NSObject>

@optional
-(BOOL)appseeSessionStarting;

@optional
-(void)appseeSessionStarted:(NSString *)sessionId videoRecorded:(BOOL)isVideoRecorded;

@optional
-(BOOL)appseeSessionEnding:(NSString *)sessionId;

@optional
-(void)appseeSessionEnded:(NSString *)sessionId;

@optional
-(NSString *)appseeScreenDetected:(NSString *)screenName;

@end


/*****************************************
NSNotificationCenter Consts - Deprecated
******************************************/

// Notification Types
extern NSString *const AppseeSessionStartedNotification __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");
extern NSString *const AppseeSessionEndedNotification   __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");
extern NSString *const AppseeScreenDetectedNotification __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");

// UserInfo Keys
extern NSString *const kAppseeSessionId                 __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");
extern NSString *const kAppseeIsVideoRecorded           __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");
extern NSString *const kAppseeScreenName                __deprecated_msg("Appsee's NSNotificationCenter messages are deprecated. Please use AppseeDelegate for receiving notifications");
