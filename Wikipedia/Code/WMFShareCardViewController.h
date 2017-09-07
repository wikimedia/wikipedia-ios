@import UIKit;
@class WMFArticle;

@interface WMFShareCardViewController : UIViewController

- (void)fillCardWithArticle:(WMFArticle *)article snippet:(NSString *)snippet image:(UIImage *)image completion:(void (^)(void))completion;

@end
