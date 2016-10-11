#import "WMFNotificationsController.h"
#import "WMFFaceDetectionCache.h"
@import ImageIO;
@import UserNotifications;
@import WMFUtilities;
@import WMFModel;

NSString *const WMFInTheNewsNotificationCategoryIdentifier = @"inTheNewsNotificationCategoryIdentifier";
NSString *const WMFInTheNewsNotificationReadNowActionIdentifier = @"inTheNewsNotificationReadNowActionIdentifier";
NSString *const WMFInTheNewsNotificationSaveForLaterActionIdentifier = @"inTheNewsNotificationSaveForLaterActionIdentifier";
NSString *const WMFInTheNewsNotificationShareActionIdentifier = @"inTheNewsNotificationShareActionIdentifier";

uint64_t const WMFNotificationUpdateInterval = 10;

NSString *const WMFNotificationInfoArticleTitleKey = @"articleTitle";
NSString *const WMFNotificationInfoArticleURLStringKey = @"articleURLString";
NSString *const WMFNotificationInfoThumbnailURLStringKey = @"thumbnailURLString";
NSString *const WMFNotificationInfoArticleExtractKey = @"articleExtract";
NSString *const WMFNotificationInfoStoryHTMLKey = @"storyHTML";
NSString *const WMFNotificationInfoViewCountsKey = @"viewCounts";

const CGFloat WMFNotificationImageCropNormalizedMinDimension = 1; //for some reason, cropping isn't respected if a full dimension (1) is indicated

@interface WMFNotificationsController ()
@property (nonatomic, strong) dispatch_queue_t notificationQueue;
@property (nonatomic, strong) dispatch_source_t notificationSource;
@end

@implementation WMFNotificationsController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.notificationQueue = dispatch_queue_create("org.wikimedia.notifications", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)start {
    [self requestAuthenticationIfNecessaryWithCompletionHandler:^(BOOL granted, NSError *_Nullable error) {
        if (error) {
            DDLogError(@"Error requesting authentication: %@", error);
        }
        dispatch_async(self.notificationQueue, ^{
            self.notificationSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.notificationQueue);
            dispatch_source_set_timer(self.notificationSource, DISPATCH_TIME_NOW, WMFNotificationUpdateInterval * NSEC_PER_SEC, WMFNotificationUpdateInterval * NSEC_PER_SEC / 10);
            dispatch_source_set_event_handler(self.notificationSource, ^{
                [self sendNotification];
            });
            dispatch_resume(self.notificationSource);
        });
    }];
}

- (void)requestAuthenticationIfNecessaryWithCompletionHandler:(void (^)(BOOL granted, NSError *__nullable error))completionHandler {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];

    UNNotificationAction *readNowAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationReadNowActionIdentifier title:MWLocalizedString(@"in-the-news-notification-read-now-action-title", nil) options:UNNotificationActionOptionForeground];
    UNNotificationAction *saveForLaterAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationShareActionIdentifier title:MWLocalizedString(@"in-the-news-notification-share-action-title", nil) options:UNNotificationActionOptionForeground];
    UNNotificationAction *shareAction = [UNNotificationAction actionWithIdentifier:WMFInTheNewsNotificationSaveForLaterActionIdentifier title:MWLocalizedString(@"in-the-news-notification-save-for-later-action-title", nil) options:UNNotificationActionOptionForeground];

    if (!readNowAction || !saveForLaterAction || !shareAction) {
        completionHandler(false, nil);
    }

    UNNotificationCategory *inTheNewsCategory = [UNNotificationCategory categoryWithIdentifier:WMFInTheNewsNotificationCategoryIdentifier actions:@[readNowAction, saveForLaterAction, shareAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone];

    if (!inTheNewsCategory) {
        completionHandler(false, nil);
    }

    [center setNotificationCategories:[NSSet setWithObject:inTheNewsCategory]];
    [center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound completionHandler:completionHandler];
}

- (void)sendNotification {
    NSString *thumbnailURLString = @"https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/President_Barack_Obama.jpg/640px-President_Barack_Obama.jpg";
    NSURL *thumbnailURL = [NSURL URLWithString:thumbnailURLString];

    WMFImageController *imageController = [WMFImageController sharedInstance];
    [imageController cacheImageWithURLInBackground:thumbnailURL
        failure:^(NSError *_Nonnull error) {

        }
        success:^(BOOL didCache) {
            NSString *cachedThumbnailPath = [imageController cachePathForImageWithURL:thumbnailURL];
            UIImage *image = [UIImage imageWithContentsOfFile:cachedThumbnailPath];
            CGFloat aspect = image.size.width / image.size.height;
            WMFFaceDetectionCache *faceDetectionCache = [WMFFaceDetectionCache sharedCache];
            BOOL useGPU = YES;
            [faceDetectionCache detectFaceBoundsInImage:image
                onGPU:useGPU
                URL:thumbnailURL
                failure:^(NSError *_Nonnull error) {

                }
                success:^(NSValue *_Nonnull faceRectValue) {
                    CGRect cropRect = CGRectMake(0, 0, 1, 1);
                    if (faceRectValue) {
                        CGRect faceRect = [faceRectValue CGRectValue];
                        if (aspect < 1) {
                            CGFloat faceMidY = CGRectGetMidY(faceRect);
                            CGFloat normalizedHeight = WMFNotificationImageCropNormalizedMinDimension * aspect;
                            CGFloat halfNormalizedHeight = 0.5 * normalizedHeight;
                            CGFloat originY = MAX(0, faceMidY - halfNormalizedHeight);
                            CGFloat normalizedWidth = MAX(faceRect.size.width, WMFNotificationImageCropNormalizedMinDimension);
                            CGFloat originX = 0.5 * (1 - normalizedWidth);
                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        } else {
                            CGFloat faceMidX = CGRectGetMidX(faceRect);
                            CGFloat normalizedWidth = WMFNotificationImageCropNormalizedMinDimension / aspect;
                            CGFloat halfNormalizedWidth = 0.5 * normalizedWidth;
                            CGFloat originX = MAX(0, faceMidX - halfNormalizedWidth);
                            CGFloat normalizedHeight = MAX(faceRect.size.height, WMFNotificationImageCropNormalizedMinDimension);
                            CGFloat originY = 0.5 * (1 - normalizedHeight);
                            cropRect = CGRectMake(originX, originY, normalizedWidth, normalizedHeight);
                        }
                    }
                    
                    
                    cropRect = CGRectApplyAffineTransform(cropRect, CGAffineTransformMakeScale(image.size.width, image.size.height));
                    
                    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
                    NSMutableData *data = [[NSMutableData alloc] init];
                    CGImageDestinationRef destinationRef = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeJPEG, 1, NULL);
                    CGImageDestinationAddImage(destinationRef, imageRef, NULL);
                    CGImageDestinationFinalize(destinationRef);
                    NSURL *croppedURL = [NSURL URLWithString:@"wikimedia://bogus"];
                    [imageController cacheImageData:data url:croppedURL MIMEType:@"image/jpeg"];
                    NSString *cachedCroppedImagePath = [imageController cachePathForImageWithURL:croppedURL];

                
                    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
                    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                    NSString *HTMLString = @"<!--Sep 25--> The <b id=\"mwCw\"><a rel=\"mw:WikiLink\" href=\"./Five_hundred_meter_Aperture_Spherical_Telescope\" title=\"Five hundred meter Aperture Spherical Telescope\" id=\"mwDA\">Five hundred meter Aperture Spherical Telescope</a></b> (FAST) makes its <a rel=\"mw:WikiLink\" href=\"./First_light_(astronomy)\" title=\"First light (astronomy)\" id=\"mwDQ\">first observations</a> in <a rel=\"mw:WikiLink\" href=\"./Guizhou\" title=\"Guizhou\" id=\"mwDg\">Guizhou</a>, China.";
                    content.title = NSLocalizedString(@"in-the-news-notification-title", nil);
                    content.body = [HTMLString wmf_stringByRemovingHTML];
                    content.categoryIdentifier = WMFInTheNewsNotificationCategoryIdentifier;
                    UNNotificationAttachment *attachement = [UNNotificationAttachment attachmentWithIdentifier:thumbnailURLString
                                                                                                           URL:[NSURL fileURLWithPath:cachedCroppedImagePath]
                                                                                                       options:@{ UNNotificationAttachmentOptionsTypeHintKey: (id)kUTTypeJPEG, UNNotificationAttachmentOptionsThumbnailClippingRectKey: (__bridge_transfer NSDictionary *)CGRectCreateDictionaryRepresentation(CGRectMake(0, 0, 1, 1)) }
                                                                                                         error:nil];
                    if (attachement) {
                        content.attachments = @[attachement];
                    }
                    content.userInfo = @{
                        WMFNotificationInfoArticleTitleKey: @"Five hundred meter Aperture Spherical Telescope",
                        WMFNotificationInfoArticleURLStringKey: @"https://en.wikipedia.org/wiki/Five_hundred_meter_Aperture_Spherical_Telescope",
                        WMFNotificationInfoThumbnailURLStringKey: thumbnailURLString,
                        WMFNotificationInfoArticleExtractKey: @"The Five hundred metre Aperture Spherical Telescope (FAST; Chinese: 五百米口径球面射电望远镜), nicknamed Tianyan (天眼, lit. \"Heavenly Eye\" or \"The Eye of Heaven\"), is a radio telescope located in the Dawodang depression (大窝凼洼地), a natural basin in Pingtang County, Guizhou Province, southwest China.",
                        WMFNotificationInfoStoryHTMLKey: HTMLString,
                        WMFNotificationInfoViewCountsKey: @[@110000, @123000, @145000, @210000, @198000, @235000, @867539]
                    };
                    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 repeats:NO];
                    NSString *identifier = [[NSUUID UUID] UUIDString];
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
                    [center addNotificationRequest:request
                             withCompletionHandler:^(NSError *_Nullable error) {
                                 if (error) {
                                     DDLogError(@"Error adding notification request: %@", error);
                                 }
                             }];
                }];

        }];
}

- (void)stop {
    dispatch_async(self.notificationQueue, ^{
        if (self.notificationSource) {
            dispatch_source_cancel(self.notificationSource);
            self.notificationSource = NULL;
        }
    });
}

@end
