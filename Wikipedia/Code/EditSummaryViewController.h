
@class PreviewAndSaveViewController;
@interface EditSummaryViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) PreviewAndSaveViewController *previewVC;

@property (strong, nonatomic) NSString *summaryText;

@end
