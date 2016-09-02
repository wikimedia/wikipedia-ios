#import "UIApplication+VisualTestUtils.h"

@implementation UIApplication (VisualTestUtils)

- (NSString *)wmf_systemVersionAndWritingDirection {
    return [@[[[UIDevice currentDevice] systemVersion],
              [self wmf_userInterfaceLayoutDirectionAsString]]
        componentsJoinedByString:@"_"];
}

- (NSString *)wmf_userInterfaceLayoutDirectionAsString {
    switch (self.userInterfaceLayoutDirection) {
        case UIUserInterfaceLayoutDirectionLeftToRight:
            return @"LTR";
        case UIUserInterfaceLayoutDirectionRightToLeft:
            return @"RTL";
    }
}

@end
