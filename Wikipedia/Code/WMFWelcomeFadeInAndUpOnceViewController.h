#import <UIKit/UIKit.h>

@protocol WMFWelcomeNavigationDelegate;

@interface WMFWelcomeFadeInAndUpOnceViewController : UIViewController

@property (nonatomic) BOOL hasAlreadyFaded;

@property (weak, nonatomic) id<WMFWelcomeNavigationDelegate> delegate;

@end
