@import UIKit;
@import WMF.Swift;

@protocol WMFAddLanguageDelegate
- (void)addLanguageButtonTapped;
@end

@interface WMFArticleLanguagesSectionFooter : UITableViewHeaderFooterView <WMFThemeable>
@property (nonatomic, weak) id<WMFAddLanguageDelegate> delegate;

- (void)setTitle:(NSString *)title;
- (void)setButtonHidden:(BOOL)hidden;

@end
