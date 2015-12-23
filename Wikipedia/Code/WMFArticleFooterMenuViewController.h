#import <UIKit/UIKit.h>

@class MWKDataStore;

NS_ASSUME_NONNULL_BEGIN

@interface WMFArticleFooterMenuViewController : UIViewController

@property (nonatomic, strong, readonly) MWKDataStore* dataStore;

@property (nonatomic, strong, readonly) MWKArticle* article;

- (instancetype)initWithArticle:(MWKArticle*)article;

@end

NS_ASSUME_NONNULL_END
