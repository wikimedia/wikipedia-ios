//  Created by Monte Hurd on 1/13/14.

#import <UIKit/UIKit.h>
#import "MWNetworkOp.h"
#import "CaptchaViewController.h"

@class NSManagedObjectID;

@interface SectionEditorViewController : UIViewController <UITextViewDelegate, UIScrollViewDelegate, NetworkOpDelegate, CaptchaViewControllerRefresh, UITextFieldDelegate>

@property (strong, nonatomic) NSManagedObjectID *sectionID;

@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (weak, nonatomic) IBOutlet UIView *captchaContainer;

- (void)reloadCaptchaPushed:(id)sender;

@end
