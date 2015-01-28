
#import "WMPullToRefreshContentView.h"
#import "Defines.h"
#import "WikiGlyph_Chars.h"
#import "Masonry.h"

typedef NS_ENUM(NSUInteger, WMPullToRefreshIndeterminateProgressState){
    WMPullToRefreshIndeterminateProgressState0 = 0,
    WMPullToRefreshIndeterminateProgressState1,
    WMPullToRefreshIndeterminateProgressState2,
    WMPullToRefreshIndeterminateProgressState3
};

@interface WMPullToRefreshContentView ()

@property (assign, nonatomic, readwrite) WMPullToRefreshProgressType type;

@property (strong, nonatomic) UILabel *loadingIndicatorLabel;
@property (strong, nonatomic) UILabel *pullToRefreshLabel;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UIButton *cancelButton;


@property (nonatomic, assign) BOOL refreshing;
@property (nonatomic, strong) NSTimer* refreshAnimationTimer;
@property (nonatomic, assign) WMPullToRefreshIndeterminateProgressState indeterminateProgressAnimationState;

@end

@implementation WMPullToRefreshContentView

#pragma mark - UIView

- (instancetype)initWithFrame:(CGRect)frame type:(WMPullToRefreshProgressType)type
{
    self = [super initWithFrame:frame];
    if (self) {
     
        self.type = type;
        
        self.refreshPromptString = @"Refresh (not localized)";
        self.refreshReleaseString = @"Release to Refresh (not localized)";
        self.refreshRunningString = @"Refreshing (not localized)";
        
        self.pullToRefreshLabel = [[UILabel alloc] init];
        self.pullToRefreshLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.pullToRefreshLabel.textAlignment = NSTextAlignmentCenter;
        self.pullToRefreshLabel.numberOfLines = 1;
        self.pullToRefreshLabel.font = [UIFont systemFontOfSize:10.0 * MENUS_SCALE_MULTIPLIER];
        self.pullToRefreshLabel.textColor = [UIColor darkGrayColor];

        [self addSubview:self.pullToRefreshLabel];

        self.loadingIndicatorLabel = [[UILabel alloc] init];
        self.loadingIndicatorLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.loadingIndicatorLabel.textAlignment = NSTextAlignmentCenter;
        self.loadingIndicatorLabel.numberOfLines = 1;
        self.loadingIndicatorLabel.font = [UIFont systemFontOfSize:10.0 * MENUS_SCALE_MULTIPLIER];
        self.loadingIndicatorLabel.textColor = [UIColor darkGrayColor];
        
        [self addSubview:self.loadingIndicatorLabel];

        if(self.type == WMPullToRefreshProgressTypeDeterminate){
            
            self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            self.progressView.alpha = 0.0;

            [self addSubview:self.progressView];
            
            self.cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [self.cancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
            [self.cancelButton.titleLabel setFont:[UIFont fontWithName:@"WikiFont-Glyphs" size:20.0 * MENUS_SCALE_MULTIPLIER]];
            [self.cancelButton setTitle:WIKIGLYPH_X_CIRCLE forState:UIControlStateNormal];
            [self.cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
            self.cancelButton.alpha = 0.0;
            

            [self addSubview:self.cancelButton];
            
        }
    
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

    [self.progressView mas_remakeConstraints:^(MASConstraintMaker *make) {

        make.height.equalTo(@8.0);
        make.centerY.equalTo(self.cancelButton.mas_centerY);
        make.leading.equalTo(self).with.offset(20.0);
        make.trailing.equalTo(self.cancelButton.mas_leading).with.offset(-8.0);
    }];
    
    [self.cancelButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        
        make.bottom.equalTo(self.loadingIndicatorLabel.mas_bottom);
        make.trailing.equalTo(self.mas_right).with.offset(-20.0);
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
    
    if(self.type == WMPullToRefreshProgressTypeIndeterminate){

        self.indeterminateProgressAnimationState = WMPullToRefreshIndeterminateProgressState0;
        self.refreshAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:0.35 target:self selector:@selector(animateProgressWithTimer:) userInfo:nil repeats:YES];

    }else{

        [self setProgress:0.0 animated:NO];

        [UIView animateWithDuration:0.2 animations:^{

            self.progressView.alpha = 1.0;
            self.cancelButton.alpha = 1.0;
            self.loadingIndicatorLabel.alpha = 0.0;

        } completion:NULL];
        
        
    }
}

- (BOOL)isAnimatingProgress{
    
    if([[self.progressView.layer animationKeys] count] > 0)
        return YES;
    
    if([[self.progressView.subviews valueForKeyPath:@"layer.@unionOfArrays.animationKeys"] count] > 0)
        return YES;
    
    return NO;
}


- (void)stopAnimatingProgress{
    
    [self.refreshAnimationTimer invalidate];
    self.refreshAnimationTimer = nil;
    
    [UIView animateWithDuration:0.2 delay:0.5 options:0 animations:^{
        
        self.progressView.alpha = 0.0;
        self.cancelButton.alpha = 0.0;
        self.loadingIndicatorLabel.alpha = 1.0;
        
    } completion:NULL];

}

- (void)animateProgressWithTimer:(NSTimer*)timer{
    
    WMPullToRefreshIndeterminateProgressState newProgress = self.indeterminateProgressAnimationState + 1;
    
    if(newProgress > WMPullToRefreshIndeterminateProgressState3)
        newProgress = WMPullToRefreshIndeterminateProgressState0;
    
    self.indeterminateProgressAnimationState = newProgress;
}

- (void)setIndeterminateProgressAnimationState:(WMPullToRefreshIndeterminateProgressState)animationProgress{
    
    _indeterminateProgressAnimationState = animationProgress;
    
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

- (void)setProgress:(float)progress animated:(BOOL)animated{
    
    [self.progressView setProgress:progress animated:animated];
}

- (void)cancel{
    
    if(self.refreshCancelBlock){
        
        self.refreshCancelBlock();
    }
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
    
    WMPullToRefreshIndeterminateProgressState progress;
    
    if (pullProgress < 0.5) {
        progress = WMPullToRefreshIndeterminateProgressState0;
    }else if (pullProgress < 0.75) {
        progress = WMPullToRefreshIndeterminateProgressState1;
    }else if (pullProgress < 1.0) {
        progress = WMPullToRefreshIndeterminateProgressState2;
    }else{
        progress = WMPullToRefreshIndeterminateProgressState3;
    }
    
    self.indeterminateProgressAnimationState = progress;
}




@end
