@import UIKit;
@import WMF.Swift;

typedef NS_ENUM(NSUInteger, WMFTableHeaderFooterLabelViewType) {
    WMFTableHeaderFooterLabelViewType_Header,
    WMFTableHeaderFooterLabelViewType_Footer
};

@interface WMFTableHeaderFooterLabelView : UITableViewHeaderFooterView <WMFThemeable>
@property (nonatomic, assign) WMFTableHeaderFooterLabelViewType type;
@property (copy, nonatomic) NSString *text;
- (CGFloat)heightWithExpectedWidth:(CGFloat)width;

@property (weak, nonatomic, readonly) UIButton *clearButton;
@property (nonatomic, getter=isClearButtonHidden) BOOL clearButtonHidden;
@property (nonatomic, getter=isLabelVerticallyCentered) BOOL labelVerticallyCentered;

- (void)addClearButtonTarget:(id)target selector:(SEL)selector;

- (void)prepareForReuse;

- (void)setShortTextAsProse:(NSString *)text;

@end
