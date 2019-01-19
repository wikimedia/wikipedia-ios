@import UIKit;
@import WMF.Swift;

@class MWKSection, SavedPagesFunnel, EditFunnel, PreviewAndSaveViewController;

@protocol PreviewAndSaveViewControllerDelegate <NSObject>

- (void)previewViewControllerDidSave:(PreviewAndSaveViewController *)previewViewController;

@end

@interface PreviewAndSaveViewController : UIViewController <WMFThemeable>

@property (strong, nonatomic) MWKSection *section;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;
@property (strong, nonatomic) SavedPagesFunnel *savedPagesFunnel;

@property (strong, nonatomic) NSString *summaryText;

@property (weak, nonatomic) id<PreviewAndSaveViewControllerDelegate> delegate;

@end
