@import Foundation;
#import <WMF/WMFBlockDefinitions.h>
#import <WMF/WMFFetcher.h>

@class WMFAnnouncement;

@interface WMFAnnouncementsFetcher : WMFFetcher

- (void)fetchAnnouncementsForURL:(NSURL *)siteURL force:(BOOL)force failure:(WMFErrorHandler)failure success:(void (^)(NSArray<WMFAnnouncement *> *announcements))success;

@end
