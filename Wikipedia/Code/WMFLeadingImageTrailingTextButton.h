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
@property (nonatomic, strong) NSString *labelText;

/**
 *  The selected text shown to the right of the image.
 */
@property (nonatomic, strong) NSString *selectedLabelText;

/**
 *  The space between the elements. Default == 12
 */
@property (nonatomic, assign) CGFloat spaceBetweenIconAndText;

@end

@interface WMFLeadingImageTrailingTextButton (WMFConfiguration)

/**
 *  Configured button with save icon and text
 *
 */
- (void)configureAsSaveButton;

/**
 *  COnfigured button with bug icon and text
 */
- (void)configureAsReportBugButton;

@end
