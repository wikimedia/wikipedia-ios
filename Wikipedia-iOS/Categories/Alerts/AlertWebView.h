//  Created by Monte Hurd on 1/29/14.

#import <UIKit/UIKit.h>

@interface AlertWebView : UIView <UIWebViewDelegate>

- (instancetype)initWithHtml: (NSString *)html
                 bannerImage: (UIImage *)bannerImage
                 bannerColor: (UIColor *)bannerColor;

@end
