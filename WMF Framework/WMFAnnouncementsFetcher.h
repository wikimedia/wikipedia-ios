@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFLegacyFetcher.h>

@class WMFAnnouncement;

@interface WMFAnnouncementsFetcher : WMFLegacyFetcher

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success;

@end
