@import UIKit;
@class WMFArticle;

@interface WMFShareCardViewController : UIViewController

- (void)fillCardWithArticle:(nullable WMFArticle *)article snippet:(nullable NSString *)snippet image:(nullable UIImage *)image completion:(nullable void (^)(void))completion;

@end
