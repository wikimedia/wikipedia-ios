#import "WMFArticleViewController.h"

@interface WMFRandomArticleViewController : WMFArticleViewController

#if WMF_TWEAKS_ENABLED
@property (nonatomic, getter=isPermaRandomMode) BOOL permaRandomMode;
#endif
@end
