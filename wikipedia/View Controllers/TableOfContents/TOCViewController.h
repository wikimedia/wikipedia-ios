//  Created by Monte Hurd on 12/26/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>
#import "ToCInteractionFunnel.h"

@class WebViewController;

@interface TOCViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

-(void)centerCellForWebViewTopMostSectionAnimated:(BOOL)animated;

@property (weak, nonatomic) WebViewController *webVC;

-(void)setTocSectionDataForSections:(NSArray *)sections;

-(void)willShow;
-(void)didHide;

@end
