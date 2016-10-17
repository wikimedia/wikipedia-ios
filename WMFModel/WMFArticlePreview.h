#import <Mantle/Mantle.h>
@import CoreLocation;

@interface WMFArticlePreview : MTLModel

@property (nonatomic, copy, readwrite) NSURL *url;

@property (nonatomic, copy, readwrite) NSString *displayTitle;

@property (nonatomic, copy, readwrite) NSString *wikidataDescription;

@property (nonatomic, copy, readwrite) NSString *snippet;

@property (nonatomic, copy, readwrite) NSURL *thumbnailURL;

@property (nonatomic, copy, readwrite) CLLocation *location;

@property (nonatomic, copy, readwrite) NSDictionary<NSDate *, NSNumber *> *pageViews;

- (NSArray<NSNumber *> *)pageViewsSortedByDate;

@end
