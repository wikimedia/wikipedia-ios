@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@protocol WMFSearchButtonProviding

@end

@interface WMFSearchButton : UIBarButtonItem

- (instancetype)initWithTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
