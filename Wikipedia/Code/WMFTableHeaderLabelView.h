@import UIKit;
@import WMF.Swift;

@interface WMFTableHeaderLabelView : UITableViewHeaderFooterView <WMFThemeable>
@property (copy, nonatomic) NSString *text;
- (CGFloat)heightWithExpectedWidth:(CGFloat)width;

@property (weak, nonatomic, readonly) UIButton *clearButton;
@property (nonatomic, getter=isClearButtonHidden) BOOL clearButtonHidden;
@property (nonatomic, getter=isLabelVerticallyCentered) BOOL labelVerticallyCentered;

- (void)addClearButtonTarget:(id)target selector:(SEL)selector;

- (void)prepareForReuse;

- (void)setShortTextAsProse:(NSString *)text;

@end
