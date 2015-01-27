

#import "SSPullToRefreshView.h"

@protocol WMPullToRefreshContentView <SSPullToRefreshContentView>

@property (strong, nonatomic) NSString *refreshPromptString;
@property (strong, nonatomic) NSString *refreshReleaseString;
@property (strong, nonatomic) NSString *refreshRunningString;

@end

@interface WMPullToRefreshContentView : UIView<WMPullToRefreshContentView>


@end
