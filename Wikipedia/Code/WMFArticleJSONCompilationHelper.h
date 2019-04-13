
#import <Foundation/Foundation.h>
@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleJSONCompilationHelper : NSObject

+ (nullable NSData *)jsonDataForArticle: (MWKArticle *)article withImageWidth: (NSInteger)imageWidth;
@end

NS_ASSUME_NONNULL_END
