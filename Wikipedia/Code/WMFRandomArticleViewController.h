#import "WMFLegacyArticleViewController.h"

@interface WMFRandomArticleViewController : WMFLegacyArticleViewController

#if WMF_TWEAKS_ENABLED
@property (nonatomic, getter=isPermaRandomMode) BOOL permaRandomMode;
#endif
@end
