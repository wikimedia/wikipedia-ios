

#import "WMPullToRefreshView.h"

typedef NS_ENUM(NSUInteger, WMPullToRefreshProgressType){
    
    WMPullToRefreshProgressTypeIndeterminate,
    WMPullToRefreshProgressTypeDeterminate
};

@interface WMPullToRefreshContentView : UIView<WMPullToRefreshContentView>

- (instancetype)initWithFrame:(CGRect)frame type:(WMPullToRefreshProgressType)type;

@property (assign, nonatomic, readonly) WMPullToRefreshProgressType type;

@property (strong, nonatomic) NSString *refreshPromptString;
@property (strong, nonatomic) NSString *refreshReleaseString;
@property (strong, nonatomic) NSString *refreshRunningString;

/**
 *  Only valid for WMPullToRefreshProgressTypeDeterminate
 */
- (void)setLoadingProgress:(float)progress animated:(BOOL)animated;

/**
 *  Execute a block when cencel button is tapped
 */
@property (copy, nonatomic) dispatch_block_t refreshCancelBlock;

@end
