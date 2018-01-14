#import "WMFArticleViewController.h"

@interface WMFRandomArticleViewController : WMFArticleViewController
@property (nonatomic) BOOL isReadingListHintHidden;
@property (nonatomic) BOOL shouldShowRandomDiceOnScroll;

#if WMF_TWEAKS_ENABLED
@property (nonatomic, getter=isPermaRandomMode) BOOL permaRandomMode;
#endif
@end
