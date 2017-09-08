@import UIKit;
@class WMFArticle;

@interface WMFShareCardViewController : UIViewController

- (void)fillCardWithArticleURL:(nullable NSURL *)articleURL articleTitle:(nullable NSString *)articleTitle articleDescription:(nullable NSString *)articleDescription text:(nullable NSString *)text image:(nullable UIImage *)image;

@end
