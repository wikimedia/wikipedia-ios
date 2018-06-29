#import "WMFSearchButton.h"
@import WMF.SessionSingleton;
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFSearchButton

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 30, 30);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    button.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"search-button-accessibility-label", nil, nil, @"Search Wikipedia", @"Accessibility label for a button that opens a search box to search Wikipedia.");

    self = [super initWithCustomView:button];
    return self;
}

@end

NS_ASSUME_NONNULL_END
