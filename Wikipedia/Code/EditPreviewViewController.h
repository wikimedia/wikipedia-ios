@import UIKit;
@import WMF.Swift;

@class MWKSection, SavedPagesFunnel, EditFunnel, EditPreviewViewController;

@protocol EditPreviewViewControllerDelegate <NSObject>

- (void)editPreviewViewControllerDidTapNext:(EditPreviewViewController *)editPreviewViewController;

@end

@interface EditPreviewViewController : UIViewController <WMFThemeable>

@property (strong, nonatomic) MWKSection *section;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;
@property (strong, nonatomic) SavedPagesFunnel *savedPagesFunnel;
@property (strong, nonatomic) WMFTheme *theme;

@property (weak, nonatomic) id<EditPreviewViewControllerDelegate> delegate;

@end
