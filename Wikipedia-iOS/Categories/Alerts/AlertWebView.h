//  Created by Monte Hurd on 1/29/14.

#import <UIKit/UIKit.h>

@interface AlertWebView : UIView <UIWebViewDelegate>

- (instancetype)initWithHtml: (NSString *)html
                   leftImage: (UIImage *)leftImage
                   labelText: (NSString *)labelText
                  rightImage: (UIImage *)rightImage
                 bannerImage: (UIImage *)bannerImage
                 bannerColor: (UIColor *)bannerColor;

@end
