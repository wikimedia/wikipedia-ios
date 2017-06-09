@import Foundation;
#import "WMFBlockDefinitions.h"

@class WMFAnnouncement;

@interface WMFAnnouncementsFetcher : NSObject

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success;

@end
