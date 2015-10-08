//  Created by Monte Hurd on 7/25/14.
//  Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

@class WMFWebViewController;
@interface ReferenceVC : UIViewController <UIWebViewDelegate>

@property (assign, nonatomic) NSInteger index;

@property (strong, nonatomic) NSString* html;

@property (strong, nonatomic) NSString* linkId;
@property (strong, nonatomic) NSString* linkText;

@property (weak, nonatomic) WMFWebViewController* webVC;

@end
