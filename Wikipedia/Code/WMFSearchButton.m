#import "WMFSearchButton.h"
#import "WMFSearchViewController.h"
@import WMF.SessionSingleton;
#import "Wikipedia-Swift.h"

NSString *const WMFShowSearchNotification = @"WMFShowSearchNotification";

NS_ASSUME_NONNULL_BEGIN

@implementation WMFSearchButton

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 30, 30);
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    self = [super initWithCustomView:button];
    return self;
}

@end

NS_ASSUME_NONNULL_END
