#import "UIViewController+WMFStoryboardUtilities.h"

#define WMFAssertExpectedVC

@implementation UIViewController (WMFStoryboardUtilities)

// Returns an instance of the receiver from the initial view controller of a storyboard matching it's class storyboard.
+ (instancetype)wmf_initialViewControllerFromClassStoryboard {
    id vc = [[self wmf_classStoryboard] instantiateInitialViewController];
    NSAssert(vc, @"Instantiating view controller %@ from storyboard %@ returned nil!", vc, [self wmf_classStoryboardName]);
    NSAssert([vc isMemberOfClass:self], @"Expected %@ to be instance of class %@", vc, self);
    return vc;
}

// Storyboard name for the receiver, defaults to NSStringFromClass(self).
+ (NSString *)wmf_classStoryboardName {
    NSString *name = NSStringFromClass(self);
    if ([name containsString:@"."]) { // Remove module prefix (added when invoked via Swift)
        name = [name componentsSeparatedByString:@"."].lastObject;
    }
    return name;
}

// UIStoryboard from the main bundle matching wmf_classStoryboardName.
+ (UIStoryboard *)wmf_classStoryboard {
    id sb = [UIStoryboard storyboardWithName:[self wmf_classStoryboardName] bundle:[NSBundle bundleForClass:self]];
    NSAssert(sb, @"Instantiating storyboard %@ returned nil!", [self wmf_classStoryboardName]);
    return sb;
}

+ (instancetype)wmf_viewControllerWithIdentifier:(NSString *)identifier
                             fromStoryboardNamed:(NSString *)storyboardName {
    UIStoryboard *storyboard =
        [UIStoryboard storyboardWithName:storyboardName
                                  bundle:[NSBundle bundleForClass:self]];
    return [self wmf_viewControllerWithIdentifier:identifier
                                   fromStoryboard:storyboard];
}

+ (instancetype)wmf_viewControllerWithIdentifier:(NSString *)identifier
                                  fromStoryboard:(UIStoryboard *)storyboard {
    UIViewController *instance = [storyboard instantiateViewControllerWithIdentifier:identifier];
    NSAssert([instance isMemberOfClass:self], @"Unexpected view controller for identifier %@. Expected instance of %@, got %@",
             identifier, self, instance);
    return instance;
}

@end
