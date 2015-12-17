#import <UIKit/UIKit.h>

@class MWKDataStore;

@interface WMFArticleFooterMenuViewController : UIViewController

@property (nonatomic, strong) MWKDataStore* dataStore;

@property (nonatomic, strong, readonly) MWKArticle* article;

- (instancetype)initWithArticle:(MWKArticle*)article;

@end
