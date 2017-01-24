#import "WMFArticle+CoreDataClass.h"

@interface WMFArticle (WMFExtensions)

@property (nonatomic, readonly, nullable) NSURL *URL;

@property (nonatomic, nullable) NSURL *thumbnailURL;

@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *pageViewsSortedByDate;

- (void)updateViewedDateWithoutTime; // call after setting viewedDate

@end
