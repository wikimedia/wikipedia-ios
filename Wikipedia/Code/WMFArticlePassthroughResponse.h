
#import <Foundation/Foundation.h>
@class MWKArticle;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticlePassthroughResponse : NSObject

@property (nonatomic, strong, nullable) MWKArticle *article;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong, nullable) NSError *error;
@property (nonatomic, assign) BOOL force;

- (instancetype)initWithArticle:(MWKArticle *)article success:(BOOL)success error:(NSError *)error force:(BOOL)force;

@end

NS_ASSUME_NONNULL_END
