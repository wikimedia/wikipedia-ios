#import "WMFAnnouncementContentGroup.h"

@interface WMFAnnouncementContentGroup ()

@property (nonatomic, strong, readwrite) NSDate *date;
@property (nonatomic, strong, readwrite) NSURL *siteURL;
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSDate *visibilityStartDate;
@property (nonatomic, strong, readwrite) NSDate *visibilityEndDate;
@property (nonatomic, assign, readwrite) BOOL wasDismissed;
@property (nonatomic, assign, readwrite) BOOL isVisible;

@end

@implementation WMFAnnouncementContentGroup

@end
