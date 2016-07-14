#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class WMFImageTagList;

@interface WMFImageTagParser : NSObject

- (WMFImageTagList*)imageTagListFromParsingHTMLString:(NSString*)HTMLString;

- (WMFImageTagList*)imageTagListFromParsingHTMLString:(NSString*)HTMLString withLeadImageURL:(nullable NSURL *)leadImageURL;

@end

NS_ASSUME_NONNULL_END
