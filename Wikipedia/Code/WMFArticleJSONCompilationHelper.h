
#import <Foundation/Foundation.h>
@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleJSONCompilationHelper : NSObject

+ (nullable NSData *)jsonDataForArticle:(MWKArticle *)article withImageWidth:(NSInteger)imageWidth;
+ (NSString *)stringByUpdatingImageTagAttributesForProxyAndScalingInImageTagContents:(NSString *)imageTagContents withBaseURL:(NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth;
+ (NSString *)stringByReplacingImageURLsWithAppSchemeURLsInHTMLString:(NSString *)HTMLString withBaseURL:(nullable NSURL *)baseURL targetImageWidth:(NSUInteger)targetImageWidth;
@end

NS_ASSUME_NONNULL_END
