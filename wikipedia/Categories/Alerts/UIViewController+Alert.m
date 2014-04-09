//  Created by Monte Hurd on 1/15/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+Alert.h"
#import "UINavigationController+Alert.h"

@implementation UIViewController (Alert)

-(void)showAlert:(NSString *)alertText
{
    [self.navigationController showAlert:alertText];
}

-(void)showHTMLAlert: (NSString *)html
      bannerImage: (UIImage *)bannerImage
      bannerColor: (UIColor *)bannerColor
{
    [self.navigationController showHTMLAlert:html bannerImage:bannerImage bannerColor:bannerColor];
}

@end
