#import <UIKit/UIKit.h>

//IB_DESIGNABLE
@interface WMFLeadingImageTrailingTextButton : UIControl

/**
 *  The image view shown to the left (in LTR) of the text.
 */
@property (nonatomic, strong) UIImage *iconImage;

/**
 *  The selected image view shown to the left (in LTR) of the text.
 */
@property (nonatomic, strong) UIImage *selectedIconImage;

/**
 *  The text shown to the right of the image.
 */
@property (nonatomic, copy) NSString *labelText;

/**
 *  The selected text shown to the right of the image.
 */
@property (nonatomic, copy) NSString *selectedLabelText;

@property (nonatomic, copy) NSString *selectedActionText;

@property (nonatomic, copy) NSString *deselectedActionText;

/**
 *  The space between the elements. Default == 12
 */
@property (nonatomic, assign) CGFloat spaceBetweenIconAndText;

/**
 * The insets around the content. Default 0,0,0,0
 * Left/Right flipped for RTL
 */
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

/**
 *  The image view shown to the left (in LTR) of the text. Exposed for configuration ONLY
 *  Use the method above to set text
 */
@property (nonatomic, strong, readonly) UIImageView *iconImageView;

/**
 *  The text shown to the right of the image. Exposed for configuration ONLY
 *  Use the method above to set image

 */
@property (nonatomic, strong, readonly) UILabel *textLabel;

@end

@interface WMFLeadingImageTrailingTextButton (WMFConfiguration)

/**
 *  Configured button with save icon and text
 *
 */
- (void)configureAsSaveButton;

/**
 *  Configured button with bug icon and text
 */
- (void)configureAsReportBugButton;

- (void)configureAsNotifyTrendingButton;

@end
