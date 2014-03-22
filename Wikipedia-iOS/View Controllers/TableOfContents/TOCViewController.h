//  Created by Monte Hurd on 12/26/13.

#import <UIKit/UIKit.h>

@class WebViewController;

@interface TOCViewController : UIViewController <UITextFieldDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) WebViewController *webVC;

-(void)centerCellForWebViewTopMostSection;

@end
