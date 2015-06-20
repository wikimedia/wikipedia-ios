//  Created by Monte Hurd on 2/27/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "CaptchaViewController.h"

@class MWKSection, SavedPagesFunnel, EditFunnel;

@interface PreviewAndSaveViewController : UIViewController <CaptchaViewControllerRefresh>

@property (strong, nonatomic) MWKSection* section;
@property (strong, nonatomic) NSString* wikiText;
@property (strong, nonatomic) EditFunnel* funnel;
@property (strong, nonatomic) SavedPagesFunnel* savedPagesFunnel;

- (void)reloadCaptchaPushed:(id)sender;

@property (strong, nonatomic) NSString* summaryText;

@end
