@import UIKit;

@interface WMFTableHeaderLabelView : UITableViewHeaderFooterView
@property (copy, nonatomic) NSString *text;
- (CGFloat)heightWithExpectedWidth:(CGFloat)width;

@property (strong, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic, readonly) UIButton *clearButton;
@property (nonatomic, getter=isClearButtonHidden) BOOL clearButtonHidden;
@property (nonatomic, getter=isLabelVerticallyCentered) BOOL labelVerticallyCentered;

- (void)addClearButtonTarget:(id)target selector:(SEL)selector;

- (void)prepareForReuse;

@end
