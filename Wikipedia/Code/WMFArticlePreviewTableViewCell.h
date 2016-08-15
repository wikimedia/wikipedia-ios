#import "WMFArticleListTableViewCell.h"

@class MWKSavedPageList;
@class MWKImage;
@class WMFSaveButtonController;

@interface WMFArticlePreviewTableViewCell : WMFArticleListTableViewCell

@property(nonatomic, strong) NSString *snippetText;

+ (CGFloat)estimatedRowHeight;

/**
 *  Wire up the save button with the title and saved page list
 *  to enable saving.
 *
 *  @param url         The url to save/unsave
 *  @param savedPageList The saved page list to update
 */
- (void)setSaveableURL:(NSURL *)url
         savedPageList:(MWKSavedPageList *)savedPageList;

@end

@interface WMFArticlePreviewTableViewCell (Outlets)

/**
 *  Cause cell to blur and show spinning loading indicator.
 *
 *  @param loading    Shows/hides blur and loading indicator
 */
- (void)setLoading:(BOOL)loading;

/**
 *  Exposed so the analytics source can be set.
 */
@property(strong, nonatomic, readonly)
    WMFSaveButtonController *saveButtonController;

@end
