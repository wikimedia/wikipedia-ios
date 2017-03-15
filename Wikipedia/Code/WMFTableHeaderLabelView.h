#import <UIKit/UIKit.h>

@interface WMFTableHeaderLabelView : UIView
@property (copy, nonatomic) NSString *text;
- (CGFloat)heightWithExpectedWidth:(CGFloat)width;

@property (weak, nonatomic, readonly) UIButton *clearButton;
@property (nonatomic, getter=isClearButtonHidden) BOOL clearButtonHidden;
@property (nonatomic, getter=isLabelVerticallyCentered) BOOL labelVerticallyCentered;

- (void)addClearButtonTarget:(id)target selector:(SEL)selector;

- (void)prepareForReuse;

@end
