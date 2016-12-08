#import "WMFArticleListTableViewCell.h"

@interface WMFArticleListTableViewCell (WMFSearch)

/**
 *  Set the receivers @c titleText, optionally highlighting the a part of the title
 *
 *  @param text          The text of the title
 *  @param highlightText The part of the title to highlight
 */
- (void)wmf_setTitleText:(NSString *)text highlightingText:(NSString *)highlightText;

@end
