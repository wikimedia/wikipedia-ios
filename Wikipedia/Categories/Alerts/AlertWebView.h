//  Created by Monte Hurd on 1/29/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@interface AlertWebView : UIView <UIWebViewDelegate>

- (instancetype)initWithHtml:(NSString*)html
                 bannerImage:(UIImage*)bannerImage
                 bannerColor:(UIColor*)bannerColor;

@end
