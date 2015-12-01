
#import "UIStoryboard+WMFExtensions.h"
#import "UIViewController+WMFStoryboardUtilities.h"

static NSString* const WMFDefaultStoryBoardName = @"iPhone_Root";

@implementation UIStoryboard (WMFExtensions)

+ (instancetype)wmf_appRootStoryBoard {
    return [self storyboardWithName:WMFDefaultStoryBoardName bundle:nil];
}

@end
