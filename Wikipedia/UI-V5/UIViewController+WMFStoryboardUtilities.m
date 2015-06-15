//  Created by Monte Hurd on 6/17/15.
//  Copyright (c) 2015 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "UIViewController+WMFStoryboardUtilities.h"

@implementation UIViewController (WMFStoryboardUtilities)

// Returns an instance of the receiver from the initial view controller of a storyboard matching it's class storyboard.
+ (instancetype)wmf_initialViewControllerFromClassStoryboard {
    id vc = [[self wmf_classStoryboard] instantiateInitialViewController];
    NSAssert(vc, @"Instantiating view controller %@ from storyboard %@ returned nil!", vc, [self wmf_classStoryboardName]);
    NSAssert([vc isMemberOfClass:self], @"Expected %@ to be instance of class %@", vc, self);
    return vc;
}

// Storyboard name for the receiver, defaults to NSStringFromClass(self).
+ (NSString*)wmf_classStoryboardName {
    return NSStringFromClass(self);
}

// UIStoryboard from the main bundle matching wmf_classStoryboardName.
+ (UIStoryboard*)wmf_classStoryboard {
    id sb = [UIStoryboard storyboardWithName:[self wmf_classStoryboardName] bundle:nil];
    NSAssert(sb, @"Instantiating storyboard %@ returned nil!", [self wmf_classStoryboardName]);
    return sb;
}

@end
