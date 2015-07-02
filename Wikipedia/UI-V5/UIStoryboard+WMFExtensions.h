
#import <UIKit/UIKit.h>

@interface UIStoryboard (WMFExtensions)

+ (UIStoryboard*)wmf_appRootStoryBoard;

+ (UIStoryboard*)wmf_storyBoardForViewControllerClass:(Class)viewControllerClass;

- (id)wmf_instantiateViewControllerWithIdentifierFromClass:(Class)viewControllerClass;

@end
