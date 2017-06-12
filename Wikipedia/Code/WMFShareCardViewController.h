@import UIKit;
@class MWKArticle;

@interface WMFShareCardViewController : UIViewController

- (void)fillCardWithMWKArticle:(MWKArticle *)article snippet:(NSString *)snippet image:(UIImage *)image
                    completion:(void (^)(void))completion;

@end
