@import UIKit;
@import WMF.Swift;

/// Table cell designed for displaying a language autonym & a page title in that language.
@interface WMFLanguageCell : UITableViewCell <WMFThemeable>

@property (strong, nonatomic) NSString *localizedLanguageName;
@property (strong, nonatomic) NSString *articleTitle;
@property (strong, nonatomic) NSString *languageName;
@property (strong, nonatomic) NSString *languageID;

@property (nonatomic) BOOL isPreferred;
@property (nonatomic) BOOL isPrimary;

- (void)collapseSideSpacing;

@end
