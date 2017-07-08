
#import "WMFMediaViewController.h"
#import "WMFMedia.h"
@import NYTPhotoViewer;
@import OGVKit;

@interface WMFMediaViewController () <WMFMediaDelegate, OGVPlayerDelegate>
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeItem;
@property (weak, nonatomic) IBOutlet OGVPlayerView *playerView;
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

    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.shadowImage = [[UIImage alloc] init];
    [self.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];

    [self setupNavigationBarImages];
}

- (void)setupNavigationBarImages {
    NSBundle *photoFramework = [NSBundle bundleForClass:[NYTPhotoViewController class]];
    NSString *photoBundlePath = [photoFramework pathForResource:@"NYTPhotoViewer" ofType:@"bundle"];
    NSBundle *photoBundle = [NSBundle bundleWithPath:photoBundlePath];
    self.closeItem.image = [UIImage imageNamed:@"NYTPhotoViewerCloseButtonX"
                                      inBundle:photoBundle
                 compatibleWithTraitCollection:nil];
    self.closeItem.landscapeImagePhone = [UIImage imageNamed:@"NYTPhotoViewerCloseButtonXLandscape"
                                                    inBundle:photoBundle
                               compatibleWithTraitCollection:nil];
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
    if (self.mediaObject) {
        CGRect bounds = self.view.bounds;
        CGFloat scaleWidth = bounds.size.width / self.mediaObject.width;
        CGFloat scaleHeight = bounds.size.height / self.mediaObject.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        [UIView performWithoutAnimation:^{
            self.playerView.frame = CGRectMake(0, 0, self.mediaObject.width * minScale, self.mediaObject.height * minScale);
            self.playerView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
        }];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)wmf_MediaSuccess:(WMFMedia *)media {
    self.mediaObject = media.highQualityMediaObject;
    [self.view setNeedsLayout];
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
