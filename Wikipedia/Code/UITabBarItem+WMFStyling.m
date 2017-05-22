#import "UITabBarItem+WMFStyling.h"

@implementation UITabBarItem (WMFStyling)

+ (NSDictionary*)wmf_rootTabBarItemStyleForState:(UIControlState)state {
    UIFont *tabBarItemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    switch (state) {
        case UIControlStateSelected:
            return @{
                     NSForegroundColorAttributeName: [UIColor wmf_blue],
                     NSFontAttributeName: tabBarItemFont
                     };
            break;
        default:
            return @{
                     NSForegroundColorAttributeName: [UIColor wmf_customGray],
                     NSFontAttributeName: tabBarItemFont
                     };
            break;
    }
}

@end
