@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class WMFImageTagList;

@interface WMFImageTagParser : NSObject

- (WMFImageTagList *)imageTagListFromParsingHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL; // baseURL will be used to complete src if it is missing a host

- (WMFImageTagList *)imageTagListFromParsingHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL leadImageURL:(nullable NSURL *)leadImageURL;

@end

NS_ASSUME_NONNULL_END
