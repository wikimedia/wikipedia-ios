#import <UIKit/UIKit.h>

@interface UIImageView (WMFPlaceholder)

- (void)wmf_hidePlaceholder;
- (void)wmf_showPlaceholder;

@property (nonatomic, readonly) UIImageView *wmf_placeholderView;

@end
