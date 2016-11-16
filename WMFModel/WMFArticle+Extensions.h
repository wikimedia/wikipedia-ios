#import "WMFArticle+CoreDataClass.h"

@interface WMFArticle (WMFExtensions)

@property (nonatomic, readonly, nullable) NSURL *URL;

@property (nonatomic, nullable) NSURL *thumbnailURL;

@property (nonatomic, nullable) CLLocation *location;

@property (nonatomic, readonly, nullable) NSArray<NSNumber *> *pageViewsSortedByDate;

@end
