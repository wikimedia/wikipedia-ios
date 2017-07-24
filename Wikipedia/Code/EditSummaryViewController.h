@import UIKit;
@import WMF.Swift;

@class PreviewAndSaveViewController;
@interface EditSummaryViewController : UIViewController <UITextFieldDelegate, WMFThemeable>

@property (weak, nonatomic) PreviewAndSaveViewController *previewVC;

@property (strong, nonatomic) NSString *summaryText;

@end
