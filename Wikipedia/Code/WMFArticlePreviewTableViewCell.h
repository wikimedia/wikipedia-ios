#import "WMFArticleListTableViewCell.h"

@class MWKTitle;
@class MWKSavedPageList;
@class MWKImage;
@class WMFSaveButtonController;

@interface WMFArticlePreviewTableViewCell : WMFArticleListTableViewCell

@property (nonatomic, strong) NSString* snippetText;

/**
 *  Wire up the save button with the title and saved page list
 *  to enable saving.
 *
 *  @param title         The title to save/unsave
 *  @param savedPageList The saved page list to update
 */
- (void)setSaveableTitle:(MWKTitle*)title savedPageList:(MWKSavedPageList*)savedPageList;

@end


@interface WMFArticlePreviewTableViewCell (Outlets)

/**
 *  Label used to display the receiver's @c snippet.
 *
 */
@property (nonatomic, strong) IBOutlet UILabel* snippetLabel;

/**
 *  The button used to display the saved state of the receiver's @c title.
 *
 *  This class will automatically
 *  configure any buttons connected to this property in Interface Builder (during @c awakeFromNib).
 */
@property (strong, nonatomic) IBOutlet UIButton* saveButton;

/**
 *  Cause cell to blur and show spinning loading indicator.
 *
 *  @param loading    Shows/hides blur and loading indicator
 */
- (void)setLoading:(BOOL)loading;


/**
 *  Exposed so the analytics source can be set.
 */
@property (strong, nonatomic, readonly) WMFSaveButtonController* saveButtonController;

@end
