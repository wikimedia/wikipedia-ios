#import <WMF/WMFNotificationsController.h>
#import <WMF/WMFFaceDetectionCache.h>
#import <WMF/WMF-Swift.h>
@import ImageIO;
@import UserNotifications;
@import CoreServices;

#define WMF_ALWAYS_ASK_FOR_NOTIFICATION_PERMISSION DEBUG && 0

NSString *const WMFInTheNewsNotificationCategoryIdentifier = @"inTheNewsNotificationCategoryIdentifier";
NSString *const WMFInTheNewsNotificationReadNowActionIdentifier = @"inTheNewsNotificationReadNowActionIdentifier";
NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier = @"inTheNewsNotificationSaveForLaterActionIdentifier";
NSString *const WMFInTheNewsNotificationShareActionIdentifier = @"inTheNewsNotificationShareActionIdentifier";

NSString *const WMFEditRevertedNotificationCategoryIdentifier = @"WMFEditRevertedNotificationCategoryIdentifier";
NSString *const WMFEditRevertedReadMoreActionIdentifier = @"WMFEditRevertedReadMoreActionIdentifier";
NSString *const WMFEditRevertedNotificationIDKey = @"WMFEditRevertedNotificationIDKey";

NSString *const WMFNotificationInfoArticleTitleKey = @"articleTitle";
NSString *const WMFNotificationInfoArticleURLStringKey = @"articleURLString";
NSString *const WMFNotificationInfoThumbnailURLStringKey = @"thumbnailURLString";
NSString *const WMFNotificationInfoArticleExtractKey = @"articleExtract";
NSString *const WMFNotificationInfoViewCountsKey = @"viewCounts";
NSString *const WMFNotificationInfoFeedNewsStoryKey = @"feedNewsStory";

//const CGFloat WMFNotificationImageCropNormalizedMinDimension = 1; //for some reason, cropping isn't respected if a full dimension (1) is indicated

@interface WMFNotificationsController ()

@property (nonatomic, readwrite, getter=isAuthorized) BOOL authorized;
@property (weak, nonatomic) MWKDataStore *dataStore;

@end

@implementation WMFNotificationsController

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
    self = [super init];
    if (self) {
        self.dataStore = dataStore;
#if WMF_ALWAYS_ASK_FOR_NOTIFICATION_PERMISSION
        [self requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error){

        }];
#endif
    }
    return self;
}

- (void)requestAuthenticationIfNecessaryWithCompletionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    if (![UNUserNotificationCenter class]) {
        completionHandler(NO, nil);
        return;
    }
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusAuthorized:
                self.authorized = YES;
                completionHandler(YES, nil);
                break;
            case UNAuthorizationStatusDenied:
                self.authorized = NO;
                completionHandler(NO, nil);
                break;
            case UNAuthorizationStatusNotDetermined:
                [self requestAuthenticationWithCompletionHandler:completionHandler];
                break;
            default:
                break;
        }
    }];
}

- (void)updateCategories {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNNotificationAction *readNowAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationReadNowActionIdentifier title:WMFLocalizedStringWithDefaultValue(@"in-the-news-notification-read-now-action-title", nil, nil, @"Read Now", @"Title on the 'Read Now' action button") options:UNNotificationActionOptionForeground];
    UNNotificationAction *shareAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationShareActionIdentifier title:WMFLocalizedStringWithDefaultValue(@"in-the-news-notification-share-action-title", nil, nil, @"Share…", @"Title on the 'Share' action button {{Identical|Share}}") options:UNNotificationActionOptionForeground];
    UNNotificationAction *saveForLaterAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationSaveForLaterActionIdentifier title:WMFLocalizedStringWithDefaultValue(@"in-the-news-notification-save-for-later-action-title", nil, nil, @"Save for later", @"Title on the 'Save for later' action button") options:UNNotificationActionOptionNone];
    UNNotificationAction *readMoreAction = [UNNotificationAction actionWithIdentifier:WMFEditRevertedReadMoreActionIdentifier title:WMFLocalizedStringWithDefaultValue(@"reverted-edit-notification-read-more-action-title", nil, nil, @"Read more", @"Title on the 'Read more' action button") options:UNNotificationActionOptionNone];

    if (!readNowAction || !saveForLaterAction || !shareAction || !readMoreAction) {
        DDLogError(@"Unable to create notification categories");
        return;
    }

    UNNotificationCategory *inTheNewsCategory = [UNNotificationCategory categoryWithIdentifier:WMFInTheNewsNotificationCategoryIdentifier actions:@[readNowAction, saveForLaterAction, shareAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

    if (!inTheNewsCategory) {
        DDLogError(@"Unable to create notification categories");
        return;
    }

    UNNotificationCategory *editRevertedCategory = [UNNotificationCategory categoryWithIdentifier:WMFEditRevertedNotificationCategoryIdentifier actions:@[readMoreAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

    [center setNotificationCategories:[NSSet setWithObjects:inTheNewsCategory, editRevertedCategory, nil]];
}

- (void)requestAuthenticationWithCompletionHandler:(void (^)(BOOL, NSError *_Nullable))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                          completionHandler:^(BOOL granted, NSError *_Nullable error) {
                              self.authorized = granted;
                              completionHandler(granted, error);
                          }];
}

- (NSString *)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents withAttachements:(nullable NSArray<UNNotificationAttachment *> *)attachements {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = title;
    content.body = body;
    content.categoryIdentifier = categoryIdentifier;
    if (attachements) {
        content.attachments = attachements;
    }
    content.userInfo = userInfo;
    UNNotificationTrigger *trigger = nil;
    if (dateComponents) {
        trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
    } else {
        trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    }
    NSString *identifier = [[NSUUID UUID] UUIDString];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
    [center addNotificationRequest:request
             withCompletionHandler:^(NSError *_Nullable error) {
                 if (error) {
                     DDLogError(@"Error adding notification request: %@", error);
                 }
             }];
    return identifier;
}

- (void)sendNotificationWithTitle:(NSString *)title body:(NSString *)body categoryIdentifier:(NSString *)categoryIdentifier userInfo:(NSDictionary *)userInfo atDateComponents:(nullable NSDateComponents *)dateComponents {
    if (![UNUserNotificationCenter class]) {
        return;
    }

    NSString *thumbnailURLString = userInfo[WMFNotificationInfoThumbnailURLStringKey];
    if (!thumbnailURLString) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    NSURL *thumbnailURL = [NSURL URLWithString:thumbnailURLString];
    if (!thumbnailURL) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    NSString *typeHint = nil;
    NSString *pathExtension = thumbnailURL.pathExtension.lowercaseString;
    if ([pathExtension isEqualToString:@"jpg"] || [pathExtension isEqualToString:@"jpeg"]) {
        typeHint = (NSString *)kUTTypeJPEG;
    }

    if (!typeHint) {
        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        return;
    }

    [self.dataStore.cacheController fetchDataWithURL:thumbnailURL
        failure:^(NSError *_Nonnull error) {
            [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
        }
        success:^(NSData *_Nonnull data, NSURLResponse *_Nonnull response) {
            WMFFaceDetectionCache *faceDetectionCache = [WMFFaceDetectionCache sharedCache];
            BOOL useGPU = YES;
            NSURL *cacheDirectory = [NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] isDirectory:YES];
            NSString *filename = [[NSUUID UUID] UUIDString];
            NSURL *cachedThumbnailURL = [cacheDirectory URLByAppendingPathComponent:filename];
            UIImage *image = [UIImage imageWithData:data];
            if (!cachedThumbnailURL || !image) {
                [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
                return;
            }
            [data writeToURL:cachedThumbnailURL atomically:YES];
            UNNotificationAttachment *attachement = [UNNotificationAttachment attachmentWithIdentifier:thumbnailURLString
                                                                                                   URL:cachedThumbnailURL
                                                                                               options:@{UNNotificationAttachmentOptionsTypeHintKey: typeHint,
                                                                                                         UNNotificationAttachmentOptionsThumbnailClippingRectKey: (__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(CGRectMake(0, 0, 1, 1))}
                                                                                                 error:nil];
            NSArray *imageAttachements = nil;
            if (attachement) {
                imageAttachements = @[attachement];
            }

            [faceDetectionCache detectFaceBoundsInImage:image
                onGPU:useGPU
                URL:thumbnailURL
                failure:^(NSError *_Nonnull error) {
                    [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:imageAttachements];
                }
                success:^(NSValue *faceRectValue) {
                    if (faceRectValue) {
                        //CGFloat aspect = image.size.width / image.size.height;
                        //                                                    CGRect cropRect = CGRectMake(0, 0, 1, 1);
                        //                                                    if (faceRectValue) {
                        //                                                        CGRect faceRect = [faceRectValue CGRectValue];
                        //                                                        if (aspect < 1) {
                        //                                                            CGFloat faceMidY = CGRectGetMidY(faceRect);
                        //                                                            CGFloat normalizedHeight = WMFNotificationImageCropNormalizedMinDimension * aspect;
                        //                                                            CGFloat halfNormalizedHeight = 0.5 * normalizedHeight;
                        //                                                            CGFloat originY = MAX(0, faceMidY - halfNormalizedHeight);
                        //                                                            CGFloat normalizedWidth = MAX(faceRect.size.width, WMFNotificationImageCropNormalizedMinDimension);
                        //                                                            CGFloat originX = 0.5 * (1 - normalizedWidth);
                        //                                                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        //                                                        } else {
                        //                                                            CGFloat faceMidX = CGRectGetMidX(faceRect);
                        //                                                            CGFloat normalizedWidth = WMFNotificationImageCropNormalizedMinDimension / aspect;
                        //                                                            CGFloat halfNormalizedWidth = 0.5 * normalizedWidth;
                        //                                                            CGFloat originX = MAX(0, faceMidX - halfNormalizedWidth);
                        //                                                            CGFloat normalizedHeight = MAX(faceRect.size.height, WMFNotificationImageCropNormalizedMinDimension);
                        //                                                            CGFloat originY = 0.5 * (1 - normalizedHeight);
                        //                                                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        //                                                        }
                        //                                                    }

                        //Since face cropping is broken, don't attach images with faces
                        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:nil];
                    } else {
                        [self sendNotificationWithTitle:title body:body categoryIdentifier:categoryIdentifier userInfo:userInfo atDateComponents:dateComponents withAttachements:imageAttachements];
                    }
                }];

        }];
}

@end
