
#import "WMPullToRefreshContentView.h"
#import "Defines.h"
#import "Masonry.h"

typedef NS_ENUM(NSUInteger, WMPullToRefreshProgressAnimationState){
    WMPullToRefreshProgressAnimationState0 = 0,
    WMPullToRefreshProgressAnimationState1,
    WMPullToRefreshProgressAnimationState2,
    WMPullToRefreshProgressAnimationState3
};

@interface WMPullToRefreshContentView ()

@property (strong, nonatomic) UILabel *loadingIndicatorLabel;
@property (strong, nonatomic) UILabel *pullToRefreshLabel;

@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, strong) NSTimer* refreshAnimationTimer;
@property (nonatomic, assign) WMPullToRefreshProgressAnimationState animationProgress;

@end

@implementation WMPullToRefreshContentView

@synthesize refreshPromptString = _refreshPromptString;
@synthesize refreshReleaseString = _refreshReleaseString;
@synthesize refreshRunningString = _refreshRunningString;

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
     
        self.refreshPromptString = @"Refresh (not localized)";
        self.refreshReleaseString = @"Release to Refresh (not localized)";
        self.refreshRunningString = @"Refreshing (not localized)";
        
        self.pullToRefreshLabel = [[UILabel alloc] init];
        self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.pullToRefreshLabel.textAlignment = NSTextAlignmentCenter;
        self.pullToRefreshLabel.numberOfLines = 1;
        self.pullToRefreshLabel.font = [UIFont systemFontOfSize:10.0 * MENUS_SCALE_MULTIPLIER];
        self.pullToRefreshLabel.textColor = [UIColor darkGrayColor];

        self.loadingIndicatorLabel = [[UILabel alloc] init];
        self.loadingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.loadingIndicatorLabel.textAlignment = NSTextAlignmentCenter;
        self.loadingIndicatorLabel.numberOfLines = 1;
        self.loadingIndicatorLabel.font = [UIFont systemFontOfSize:10.0 * MENUS_SCALE_MULTIPLIER];
        self.loadingIndicatorLabel.textColor = [UIColor darkGrayColor];

        [self addSubview:self.pullToRefreshLabel];
        [self addSubview:self.loadingIndicatorLabel];
        
    }
    return self;
}

- (void)didMoveToSuperview{
    
    [super didMoveToSuperview];
    
    [self.pullToRefreshLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.equalTo(self);
        make.centerX.equalTo(self);
    }];
    
    [self.loadingIndicatorLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(self.pullToRefreshLabel.mas_top).with.offset(-8.0);
        make.centerX.equalTo(self);
    }];

}

#pragma mark - ivars

- (void)setRefreshing:(BOOL)refreshing{
    
    _refreshing = refreshing;
    
    if(_refreshing){
        
        [self startAnimatingProgress];
        
    }else{
        
        [self stopAnimatingProgress];
    }
}

#pragma mark - Progress Animation

- (void)startAnimatingProgress{
    
    self.animationProgress = WMPullToRefreshProgressAnimationState0;
    self.refreshAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self selector:@selector(animateProgressWithTimer:) userInfo:nil repeats:YES];
    
}

- (void)stopAnimatingProgress{
    
    [self.refreshAnimationTimer invalidate];
    self.refreshAnimationTimer = nil;
    
}

- (void)animateProgressWithTimer:(NSTimer*)timer{
    
    WMPullToRefreshProgressAnimationState newProgress = self.animationProgress + 1;
    
    if(newProgress > WMPullToRefreshProgressAnimationState3)
        newProgress = WMPullToRefreshProgressAnimationState0;
    
    self.animationProgress = newProgress;
}

- (void)setAnimationProgress:(WMPullToRefreshProgressAnimationState)animationProgress{
    
    _animationProgress = animationProgress;
    
    NSLog(@"animation progress: %lu", _animationProgress);
    
    NSString *loadingText;
    
    switch (animationProgress) {
        case 0:
            loadingText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎\n";
            break;
        case 1:
            loadingText = @"▫︎ ▫︎ ▪︎ ▫︎ ▫︎\n";
            break;
        case 2:
            loadingText = @"▫︎ ▪︎ ▪︎ ▪︎ ▫︎\n";
            break;
        case 3:
            loadingText = @"▪︎ ▪︎ ▪︎ ▪︎ ▪︎\n";
            break;
        default:
            loadingText = @"▫︎ ▫︎ ▫︎ ▫︎ ▫︎\n";
            break;
    }
    
    self.loadingIndicatorLabel.text = loadingText;
}

#pragma mark - SSPullToRefreshContentView

- (void)setState:(SSPullToRefreshViewState)state withPullToRefreshView:(SSPullToRefreshView *)view{
    
    switch (state) {
        case SSPullToRefreshViewStateReady: {
            self.pullToRefreshLabel.text = self.refreshReleaseString;
            self.refreshing = NO;
            break;
        }
        case SSPullToRefreshViewStateNormal: {
            self.pullToRefreshLabel.text = self.refreshPromptString;
            self.refreshing = NO;
            break;
        }
        case SSPullToRefreshViewStateLoading:{
            self.pullToRefreshLabel.text = self.refreshRunningString;
            self.refreshing = YES;
            break;
        }
        case SSPullToRefreshViewStateClosing: {
            self.pullToRefreshLabel.text = self.refreshRunningString;
            self.refreshing = NO;
            break;
        }
    }
}


- (void)setPullProgress:(CGFloat)pullProgress{
    
    if(self.refreshing)
        return;
    
    WMPullToRefreshProgressAnimationState progress;
    
    if (pullProgress < 0.5) {
        progress = WMPullToRefreshProgressAnimationState0;
    }else if (pullProgress < 0.75) {
        progress = WMPullToRefreshProgressAnimationState1;
    }else if (pullProgress < 1.0) {
        progress = WMPullToRefreshProgressAnimationState2;
    }else{
        progress = WMPullToRefreshProgressAnimationState3;
    }
    
    self.animationProgress = progress;
}




@end
