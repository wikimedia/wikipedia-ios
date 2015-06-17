
#import <UIKit/UIKit.h>

@interface UIStoryboard (WMFExtensions)

+ (UIStoryboard*)wmf_appRootStoryBoard;

- (id)wmf_instantiateViewControllerWithIdentifierFromClass:(Class)viewControllerClass;

@end
