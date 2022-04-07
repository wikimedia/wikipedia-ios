#import <WMF/WMFNotificationsController.h>
#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/WMF-Swift.h>
@import ImageIO;
@import CoreServices;

// const CGFloat WMFNotificationImageCropNormalizedMinDimension = 1; //for some reason, cropping isn't respected if a full dimension (1) is indicated

@interface WMFNotificationsController ()

@property (weak, nonatomic) MWKDataStore *dataStore;
@property (nonatomic, readwrite, copy, nullable) NSData *remoteRegistrationDeviceToken;
@property (nonatomic, readwrite, strong, nullable) NSError *remoteRegistrationError;
@property (nonatomic, strong) WMFEchoSubscriptionFetcher *echoSubscriptionFetcher;
@property (nonatomic, strong) MWKLanguageLinkController *languageLinkController;

@end

@implementation WMFNotificationsController

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore languageLinkController:(MWKLanguageLinkController *)languageLinkController {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
        self.languageLinkController = languageLinkController;
        self.echoSubscriptionFetcher = [[WMFEchoSubscriptionFetcher alloc] initWithSession:dataStore.session configuration:dataStore.configuration];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppLanguageDidChangeNotification:) name:WMFAppLanguageDidChangeNotification object:nil];
        [self silentlyOptInToBadgePermissionsIfNecessary];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)authenticationManagerWillLogOut:(void (^)(void))completionHandler {
    NSUserDefaults.standardUserDefaults.wmf_didShowNotificationsCenterPushOptInPanel = NO;
    if (NSUserDefaults.standardUserDefaults.wmf_isSubscribedToEchoNotifications) {
        [self unsubscribeFromEchoNotificationsWithCompletionHandler:^(NSError *error) {
            completionHandler();
        }];
    } else {
        completionHandler();
    }
}

- (void)silentlyOptInToBadgePermissionsIfNecessary {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            [center requestAuthorizationWithOptions:UNAuthorizationOptionBadge
                                  completionHandler:^(BOOL granted, NSError *error){
                                      // Silently opt-in a user who has previously authorized the app for alerts and sounds into the app icon badge permission as well
                                  }];
        }
    }];
}

- (void)handleAppLanguageDidChangeNotification:(NSNotification *)notification {
    [self updatePushNotificationsCacheWithNewPrimaryAppLanguage:self.languageLinkController.appLanguage];
}

- (void)notificationPermissionsStatusWithCompletionHandler:(void (^)(UNAuthorizationStatus status))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
        completionHandler(settings.authorizationStatus);
    }];
}

- (void)requestPermissionsIfNecessaryWithCompletionHandler:(void (^)(BOOL isAllowed, NSError *__nullable error))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusNotDetermined:
                [self requestPermissionsWithCompletionHandler:completionHandler];
                break;
            case UNAuthorizationStatusDenied:
                if (completionHandler) {
                    completionHandler(NO, nil);
                }
                break;
            case UNAuthorizationStatusAuthorized:
                if (completionHandler) {
                    completionHandler(YES, nil);
                }
                break;
            case UNAuthorizationStatusProvisional:
                if (completionHandler) {
                    completionHandler(YES, nil);
                }
                break;
            case UNAuthorizationStatusEphemeral:
                if (completionHandler) {
                    completionHandler(YES, nil);
                }
                break;
        }
    }];
}

- (void)setRemoteNotificationRegistrationStatusWithDeviceToken:(nullable NSData *)deviceToken error:(nullable NSError *)error {
    self.remoteRegistrationDeviceToken = deviceToken;
    self.remoteRegistrationError = error;
}

- (void)subscribeToEchoNotificationsWithCompletionHandler:(nullable void (^)(NSError *__nullable error))completionHandler {
    [self updatePushNotificationsCacheWithNewPrimaryAppLanguage:self.languageLinkController.appLanguage];
    [self.echoSubscriptionFetcher subscribeWithSiteURL:self.languageLinkController.appLanguage.siteURL
                                           deviceToken:self.remoteRegistrationDeviceToken
                                            completion:^(NSError *__nullable error) {
                                                if (error == nil) {
                                                    NSUserDefaults.standardUserDefaults.wmf_isSubscribedToEchoNotifications = YES;
                                                }
                                                if (completionHandler) {
                                                    completionHandler(error);
                                                }
                                            }];
}

- (void)unsubscribeFromEchoNotificationsWithCompletionHandler:(nullable void (^)(NSError *__nullable error))completionHandler {
    [self.echoSubscriptionFetcher unsubscribeWithSiteURL:self.languageLinkController.appLanguage.siteURL
                                             deviceToken:self.remoteRegistrationDeviceToken
                                              completion:^(NSError *__nullable error) {
                                                  if (error == nil) {
                                                      NSUserDefaults.standardUserDefaults.wmf_isSubscribedToEchoNotifications = NO;
                                                  }

                                                  if (completionHandler) {
                                                      completionHandler(error);
                                                  }
                                              }];
}

- (void)requestPermissionsWithCompletionHandler:(void (^)(BOOL, NSError *_Nullable))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge
                          completionHandler:^(BOOL granted, NSError *_Nullable error) {
                              completionHandler(granted, error);
                          }];
}

@end
