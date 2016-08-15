#import <UIKit/UIKit.h>

@interface WMFWelcomeViewController : UIViewController

+ (instancetype)welcomeViewControllerFromDefaultStoryBoard;

@property (nonatomic, copy) dispatch_block_t completionBlock;

- (IBAction)dismiss:(id)sender;

@end
