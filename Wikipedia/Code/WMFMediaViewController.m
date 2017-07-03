
#import "WMFMediaViewController.h"
#import "WMFMedia.h"
@import OGVKit;

@interface WMFMediaViewController () <WMFMediaDelegate, OGVPlayerDelegate>
@property (weak, nonatomic) IBOutlet OGVPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic) WMFMediaObject *mediaObject;
@property (nonatomic) WMFMedia *media;
@end

@implementation WMFMediaViewController

- (instancetype)initWithTitles:(NSString *)titles {
    NSParameterAssert(titles);
    if (!titles)
        return nil;
    if (self = [super init])
        _media = [[WMFMedia alloc] initWithTitles:titles withAsyncDelegate:self];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.playerView.delegate = self;
    [self.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillResignActive:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillResignActiveNotification
                                                  object:nil];
}

- (void)appWillResignActive:(NSNotification *)notification {
    [self.playerView pause];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.mediaObject)
        [self layoutPlayer];
}

- (void)layoutPlayer {
    CGRect bounds = self.view.bounds;
    CGFloat scaleWidth = bounds.size.width / self.mediaObject.width;
    CGFloat scaleHeight = bounds.size.height / self.mediaObject.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    [UIView performWithoutAnimation:^{
        self.playerView.frame = CGRectMake(0, 0, self.mediaObject.width * minScale, self.mediaObject.height * minScale);
        self.playerView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)wmf_MediaSuccess:(WMFMedia *)media {
    self.mediaObject = media.lowQualityMediaObject;
    [self layoutPlayer];
    self.playerView.sourceURL = self.mediaObject.url;
    [self.playerView play];
}

- (void)wmf_MediaFailed:(WMFMedia *)media {
    // TODO
}

- (IBAction)close:(id)sender {
    [self.playerView pause];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
