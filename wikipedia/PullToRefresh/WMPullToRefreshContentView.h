

#import "SSPullToRefreshView.h"

typedef NS_ENUM(NSUInteger, WMPullToRefreshProgressType){
    
    WMPullToRefreshProgressTypeIndeterminate,
    WMPullToRefreshProgressTypeDeterminate
};

@interface WMPullToRefreshContentView : UIView<SSPullToRefreshContentView>

- (instancetype)initWithFrame:(CGRect)frame type:(WMPullToRefreshProgressType)type;

@property (assign, nonatomic, readonly) WMPullToRefreshProgressType type;

@property (strong, nonatomic) NSString *refreshPromptString;
@property (strong, nonatomic) NSString *refreshReleaseString;
@property (strong, nonatomic) NSString *refreshRunningString;

/**
 *  Only valid for WMPullToRefreshProgressTypeDeterminate
 */
- (void)setProgress:(float)progress animated:(BOOL)animated;

/**
 *  Execute a block when
 */
@property (copy, nonatomic) dispatch_block_t refreshCancelBlock;

- (BOOL)isAnimatingProgress;

@end
