//  Created by Monte Hurd on 2/19/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import <UIKit/UIKit.h>

// Presently it is assumed this view controller will be used only as a
// child view controller of another view controller.

@protocol CaptchaViewControllerRefresh <NSObject>
// Protocol for notifying this view controller's parent view controller
// that this view controller's refresh captcha button has been pushed.
- (void)reloadCaptchaPushed:(id)sender;
@end

@interface CaptchaViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView* captchaImageView;
@property (weak, nonatomic) IBOutlet UITextField* captchaTextBox;

@end
