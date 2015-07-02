
#import "UIStoryboard+WMFExtensions.h"

NSString* const WMFDefaultStoryBoardName = @"iPhone_Root";

@implementation UIStoryboard (WMFExtensions)

+ (UIStoryboard*)wmf_appRootStoryBoard {
    return [UIStoryboard storyboardWithName:WMFDefaultStoryBoardName bundle:nil];
}

+ (UIStoryboard*)wmf_storyBoardForViewControllerClass:(Class)viewControllerClass {
    id sb = [UIStoryboard storyboardWithName:NSStringFromClass(viewControllerClass) bundle:nil];
    NSAssert(sb, @"Instantiating storyboard %@ returned nil!", NSStringFromClass(viewControllerClass));
    return sb;
}

- (id)wmf_instantiateViewControllerWithIdentifierFromClass:(Class)viewControllerClass {
    return [self instantiateViewControllerWithIdentifier:NSStringFromClass(viewControllerClass)];
}

@end
