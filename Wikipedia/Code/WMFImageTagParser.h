#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WMFImageTagParser : NSObject

- (nullable NSArray<NSURL*>*)parseImageURLsFromHTMLString:(NSString*)HTMLString targetWidth:(NSUInteger)targetWidth;

@end

NS_ASSUME_NONNULL_END
