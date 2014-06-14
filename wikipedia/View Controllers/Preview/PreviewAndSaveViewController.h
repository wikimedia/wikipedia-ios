//  Created by Monte Hurd on 2/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CaptchaViewController.h"
#import "EditFunnel.h"

@class NSManagedObjectID;

@interface PreviewAndSaveViewController : UIViewController <NetworkOpDelegate, UITextFieldDelegate, CaptchaViewControllerRefresh, UIScrollViewDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;

-(void)reloadCaptchaPushed:(id)sender;

@property (strong, nonatomic) NSString *summaryText;

@end
