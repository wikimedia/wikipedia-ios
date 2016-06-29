#import "WMFImageTagList.h"

@interface WMFImageTagList (ImageURLs)

- (NSArray<NSURL*>*)imageURLsForGallery;
- (NSArray<NSURL*>*)imageURLsForSaving;

@end
