//
//  RMessage.h
//  RMessage
//
//  Created by Adonis Peralta on 12/7/15.
//  Copyright © 2015 Adonis Peralta. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RMessageView;

typedef NS_ENUM(NSInteger, RMessageType) {
  RMessageTypeNormal = 0,
  RMessageTypeWarning,
  RMessageTypeError,
  RMessageTypeSuccess,
  RMessageTypeCustom
};

typedef NS_ENUM(NSInteger, RMessagePosition) {
  RMessagePositionTop = 0,
  RMessagePositionNavBarOverlay,
  RMessagePositionBottom
};

/** This enum can be passed to the duration parameter */
typedef NS_ENUM(NSInteger, RMessageDuration) { RMessageDurationAutomatic = 0, RMessageDurationEndless = -1 };

/** Define on which position a specific RMessage should be displayed */
@protocol RMessageProtocol <NSObject>

@optional

/** Implement this method to manipulate the vertical message offset for a specific message */
- (CGFloat)customVerticalOffsetForMessageView:(RMessageView *)messageView;

/** You can customize the given RMessageView, like setting its alpha via (messageOpacity) or adding
 a subview */
- (void)customizeMessageView:(RMessageView *)messageView;

@end

@interface RMessage : NSObject

/** By setting this delegate it's possible to set a custom offset for the message view */
@property (nonatomic, weak) id<RMessageProtocol> delegate;

+ (instancetype)sharedMessage;

/**
 Shows a notification message
 @param message The title of the message view
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param callback The block that should be executed, when the user tapped on the message
 */
+ (void)showNotificationWithTitle:(NSString *)message
                             type:(RMessageType)type
                   customTypeName:(NSString *)customTypeName
                         callback:(void (^)(void))callback;

/**
 Shows a notification message
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param callback The block that should be executed, when the user tapped on the message
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(RMessageType)type
                   customTypeName:(NSString *)customTypeName
                         callback:(void (^)(void))callback;

/**
 Shows a notification message
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param callback The block that should be executed, when the user tapped on the message
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(RMessageType)type
                   customTypeName:(NSString *)customTypeName
                         duration:(NSTimeInterval)duration
                         callback:(void (^)(void))callback;

/**
 Shows a notification message
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param duration The duration of the notification being displayed
 @param callback The block that should be executed, when the user tapped on the message
 @param dismissingEnabled Should the message be dismissed when the user taps/swipes it
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             type:(RMessageType)type
                   customTypeName:(NSString *)customTypeName
                         duration:(NSTimeInterval)duration
                         callback:(void (^)(void))callback
             canBeDismissedByUser:(BOOL)dismissingEnabled;

/**
 Shows a notification message
 @param title The title of the message view
 @param subtitle The message that is displayed underneath the title (optional)
 @param iconImage A custom icon image (optional)
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param duration The duration of the notification being displayed
 @param callback The block that should be executed, when the user tapped on the message
 @param buttonTitle The title for button (optional)
 @param buttonCallback The block that should be executed, when the user tapped on the button
 @param messagePosition The position of the message on the screen
 @param dismissingEnabled Should the message be dismissed when the user taps/swipes it
 */
+ (void)showNotificationWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                        iconImage:(UIImage *)iconImage
                             type:(RMessageType)type
                   customTypeName:(NSString *)customTypeName
                         duration:(NSTimeInterval)duration
                         callback:(void (^)(void))callback
                      buttonTitle:(NSString *)buttonTitle
                   buttonCallback:(void (^)(void))buttonCallback
                       atPosition:(RMessagePosition)messagePosition
             canBeDismissedByUser:(BOOL)dismissingEnabled;

/**
 Shows a notification message in a specific view controller
 @param viewController The view controller to show the notification in.
 You can use +setDefaultViewController: to set the the default one instead
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param callback The block that should be executed, when the user tapped on the message
 */
+ (void)showNotificationInViewController:(UIViewController *)viewController
                                   title:(NSString *)title
                                subtitle:(NSString *)subtitle
                                    type:(RMessageType)type
                          customTypeName:(NSString *)customTypeName
                                callback:(void (^)(void))callback;

/**
 Shows a notification message in a specific view controller
 @param viewController The view controller to show the notification in.
 You can use +setDefaultViewController: to set the the default one instead
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param duration The duration of the notification being displayed
 @param callback The block that should be executed, when the user tapped on the message
 */
+ (void)showNotificationInViewController:(UIViewController *)viewController
                                   title:(NSString *)title
                                subtitle:(NSString *)subtitle
                                    type:(RMessageType)type
                          customTypeName:(NSString *)customTypeName
                                duration:(NSTimeInterval)duration
                                callback:(void (^)(void))callback;

/**
 Shows a notification message in a specific view controller
 @param viewController The view controller to show the notification in.
 You can use +setDefaultViewController: to set the the default one instead
 @param title The title of the message view
 @param subtitle The text that is displayed underneath the title
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param duration The duration of the notification being displayed
 @param callback The block that should be executed, when the user tapped on the message
 @param dismissingEnabled Should the message be dismissed when the user taps/swipes it
 */
+ (void)showNotificationInViewController:(UIViewController *)viewController
                                   title:(NSString *)title
                                subtitle:(NSString *)subtitle
                                    type:(RMessageType)type
                          customTypeName:(NSString *)customTypeName
                                duration:(NSTimeInterval)duration
                                callback:(void (^)(void))callback
                    canBeDismissedByUser:(BOOL)dismissingEnabled;

/**
 Shows a notification message in a specific view controller
 @param viewController The view controller to show the notification in.
 @param title The title of the message view
 @param subtitle The message that is displayed underneath the title (optional)
 @param iconImage A custom icon image (optional)
 @param type The message type (Message, Warning, Error, Success, Custom)
 @param customTypeName The string identifier/key for the custom style to use from specified custom
 design file. Only use when specifying an additional custom design file and when the type parameter in this call is
 RMessageTypeCustom
 @param duration The duration of the notification being displayed
 @param callback The block that should be executed, when the user tapped on the message
 @param buttonTitle The title for button (optional)
 @param buttonCallback The block that should be executed, when the user tapped on the button
 @param messagePosition The position of the message on the screen
 @param dismissingEnabled Should the message be dismissed when the user taps/swipes it
 */
+ (void)showNotificationInViewController:(UIViewController *)viewController
                                   title:(NSString *)title
                                subtitle:(NSString *)subtitle
                               iconImage:(UIImage *)iconImage
                                    type:(RMessageType)type
                          customTypeName:(NSString *)customTypeName
                                duration:(NSTimeInterval)duration
                                callback:(void (^)(void))callback
                             buttonTitle:(NSString *)buttonTitle
                          buttonCallback:(void (^)(void))buttonCallback
                              atPosition:(RMessagePosition)messagePosition
                    canBeDismissedByUser:(BOOL)dismissingEnabled;

/**
 Fades out the currently displayed notification. If another notification is in the queue,
 the next one will be displayed automatically
 @return YES if the currently displayed notification was successfully dismissed. NO if no
 notification was currently displayed.
 */
+ (BOOL)dismissActiveNotification;

/**
 Fades out the currently displayed notification. If any notifications are in the queue,
 they won't be displayed
 @return YES if the currently displayed notification was successfully dismissed. NO if no
 notification was currently displayed.
 */
+ (BOOL)dismissAllNotificationsWithCompletion:(void (^)(void))completionBlock;


/**
 Fades out the currently displayed notification with a completion block after the animation has
 finished. If another notification is in the queue, the next one will be displayed automatically
 @return YES if the currently displayed notification was successfully dismissed. NO if no
 notification was currently displayed.
 */
+ (BOOL)dismissActiveNotificationWithCompletion:(void (^)(void))completionBlock;

/** Use this method to set a default view controller to display the messages in */
+ (void)setDefaultViewController:(UIViewController *)defaultViewController;

/** Set a delegate to have full control over the position of the message view */
+ (void)setDelegate:(id<RMessageProtocol>)delegate;

/** Use this method to use custom designs in your messages. Must be a JSON formatted file - do not include the .json
 extension in the name*/
+ (void)addDesignsFromFileWithName:(NSString *)filename inBundle:(NSBundle *)bundle;

/** Indicates whether a notification is currently active. */
+ (BOOL)isNotificationActive;

/** Returns the currently queued array of RMessageView */
+ (NSArray *)queuedMessages;

/** Prepares the message view to be displayed in the future. It is queued and then displayed in
 fadeInCurrentNotification. You don't have to use this method. */
+ (void)prepareNotificationForPresentation:(RMessageView *)messageView;

/**
 Call this method to notify any presenting or on screen messages that the interface has rotated.
 Ideally should go inside the calling view controllers viewWillTransitionToSize:withTransitionCoordinator: method.
 */
+ (void)interfaceDidRotate;

+ (RMessageView *)currentMessageView;

@end
