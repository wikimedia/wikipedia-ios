#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFGalleryImageListParser : NSObject

- (nullable NSArray<NSURL*>*)parseGalleryImageURLsFromHTMLString:(NSString*)HTMLString targetWidth:(NSUInteger)targetWidth;

@end

NS_ASSUME_NONNULL_END
