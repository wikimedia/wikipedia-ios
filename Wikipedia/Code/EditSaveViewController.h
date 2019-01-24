@import UIKit;
@import WMF.Swift;

@class MWKSection, SavedPagesFunnel, EditFunnel, EditSaveViewController;

@protocol EditSaveViewControllerDelegate <NSObject>

- (void)editSaveViewControllerDidSave:(EditSaveViewController *)editSaveViewController;

@end

@interface EditSaveViewController : UIViewController <WMFThemeable>

@property (strong, nonatomic) MWKSection *section;
@property (strong, nonatomic) NSString *wikiText;
@property (strong, nonatomic) EditFunnel *funnel;
@property (strong, nonatomic) SavedPagesFunnel *savedPagesFunnel;
@property (strong, nonatomic) WMFTheme *theme;

@property (weak, nonatomic) id<EditSaveViewControllerDelegate> delegate;

@end
