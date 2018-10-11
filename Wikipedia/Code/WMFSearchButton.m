#import "WMFSearchButton.h"
@import WMF.SessionSingleton;
#import "Wikipedia-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WMFSearchButton

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:target action:action]) {
        self.accessibilityLabel = WMFLocalizedStringWithDefaultValue(@"search-button-accessibility-label", nil, nil, @"Search Wikipedia", @"Accessibility label for a button that opens a search box to search Wikipedia.");
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
