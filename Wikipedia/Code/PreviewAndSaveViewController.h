#import "Wikipedia-Swift.h"

@class MWKSection, SavedPagesFunnel, EditFunnel, PreviewAndSaveViewController;

@protocol PreviewAndSaveViewControllerDelegate <NSObject>

- (void)previewViewControllerDidSave:(PreviewAndSaveViewController *)previewViewController;

@end

@interface PreviewAndSaveViewController : UIViewController <WMFCaptchaViewControllerRefresh>

@property (strong, nonatomic) MWKSection *section;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;
@property (strong, nonatomic) SavedPagesFunnel *savedPagesFunnel;

- (void)reloadCaptchaPushed:(id)sender;

@property (strong, nonatomic) NSString *summaryText;

@property (weak, nonatomic) id<PreviewAndSaveViewControllerDelegate> delegate;

@end
