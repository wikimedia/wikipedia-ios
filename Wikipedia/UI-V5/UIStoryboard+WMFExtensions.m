
#import "UIStoryboard+WMFExtensions.h"

NSString* const WMFDefaultStoryBoardName = @"iPhone_Root";

@implementation UIStoryboard (WMFExtensions)

+ (UIStoryboard*)wmf_appRootStoryBoard {
    return [UIStoryboard storyboardWithName:WMFDefaultStoryBoardName bundle:nil];
}

- (id)wmf_instantiateViewControllerWithIdentifierFromClass:(Class)viewControllerClass {
    return [self instantiateViewControllerWithIdentifier:NSStringFromClass(viewControllerClass)];
}

@end
