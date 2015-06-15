
#import "WMFArticleListCollectionViewController.h"
#import "UICollectionView+WMFExtensions.h"
#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"

#import "TGLStackedLayout.h"
#import "WMFBottomStackLayout.h"
#import "WMFOffScreenFlowLayout.h"

#import "WMFArticleCardTranstion.h"

#import "WebViewController.h"
#import "UIViewController+WMFStoryboardUtilities.h"

@interface WMFArticleListCollectionViewController ()<TGLStackedLayoutDelegate>

@property (nonatomic, assign, readwrite) WMFArticleListMode mode;

@property (nonatomic, strong) TGLStackedLayout* stackedLayout;
@property (nonatomic, strong) WMFBottomStackLayout* bottomStackLayout;

@property (strong, nonatomic) WMFArticleCardTranstion* cardTransition;

@end

@implementation WMFArticleListCollectionViewController

#pragma mark - List Mode

- (void)setListMode:(WMFArticleListMode)mode animated:(BOOL)animated{
    
    if(_mode == mode){
        return;
    }
    
    _mode = mode;
    
    if([self isViewLoaded]){
        [self updateListForMode:_mode animated:animated];
    }
}

- (void)updateListForMode:(WMFArticleListMode)mode animated:(BOOL)animated{


    UICollectionViewLayout* layout;
    
    switch (mode) {
        case WMFArticleListModeBottomStacked:{
            self.bottomStackLayout.itemSize = self.view.bounds.size;
            layout = self.bottomStackLayout;
            
        }
            break;
        case WMFArticleListModeNormal:
        default:{
            self.stackedLayout.itemSize = self.view.bounds.size;
            layout = self.stackedLayout;
        }
            break;
    }
    

    __weak __typeof(self)weakSelf = self;
    [self setOffsecreenLayoutAnimated:animated completion:^(BOOL finished) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        [strongSelf.collectionView setCollectionViewLayout:layout animated:animated completion:^(BOOL finished) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
            if(mode == WMFArticleListModeBottomStacked){
                strongSelf.collectionView.scrollEnabled = NO;
            }else{
                strongSelf.collectionView.scrollEnabled = YES;
            }
        }];
    }];
}

/**
 * HACK: For some reason UIKit is deadlocking when switching directly
 * from bottom stacked -> stacked layouts.
 * The only solution I could find was to switch to an intermdeiate layout
 * first. This moves the items off screen and then brings them back.
 */
- (void)setOffsecreenLayoutAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion{

    WMFOffScreenFlowLayout* offscreen = [[WMFOffScreenFlowLayout alloc] init];
    offscreen.itemSize = self.view.bounds.size;
    
    [self.collectionView wmf_setCollectionViewLayout:offscreen animated:animated alwaysFireCompletion:completion];
}


#pragma mark - Accessors

- (TGLStackedLayout*)stackedLayout {
    if(!_stackedLayout){
        TGLStackedLayout* stacked = [[TGLStackedLayout alloc] init];
        stacked.fillHeight   = YES;
        stacked.alwaysBounce = YES;
        stacked.delegate     = self;
        stacked.itemSize = self.view.bounds.size;
        _stackedLayout = stacked;
    }
    
    return _stackedLayout;
}

- (WMFBottomStackLayout*)bottomStackLayout {
    
    if(!_bottomStackLayout){
        WMFBottomStackLayout* stack = [[WMFBottomStackLayout alloc] init];
        stack.itemSize = self.view.bounds.size;
        _bottomStackLayout = stack;
    }
    
    return _bottomStackLayout;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self.dataSource displayTitle];
    
    [self updateListForMode:self.mode animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateCellSizeBasedOnViewFrame];










// Warning! remove this! debugging code for showing web view!
    [[WMFArticlePresenter sharedInstance] presentCurrentArticle];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

// iOS 7 Rotation Support
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [UIView animateWithDuration:duration animations:^{
        [self updateCellSizeBasedOnViewFrame];
    }];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS 8+ Rotation Support
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id < UIViewControllerTransitionCoordinatorContext > context)
    {
        [self updateCellSizeBasedOnViewFrame];
    }                            completion:NULL];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - Update Cell Size

- (void)updateCellSizeBasedOnViewFrame {
    self.stackedLayout.itemSize = self.view.bounds.size;
    self.bottomStackLayout.itemSize = self.view.bounds.size;
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.dataSource articleCount];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WMFArticleViewControllerContainerCell class]) forIndexPath:indexPath];

    if (cell.viewController == nil) {
        WMFArticleViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([WMFArticleViewController class])];
        [cell setViewControllerAndAddViewToContentView:vc];
    }

    [self addChildViewController:cell.viewController];

    MWKArticle* article = [self.dataSource articleForIndexPath:indexPath];
    cell.viewController.article = article;

    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView*)collectionView willDisplayCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController didMoveToParentViewController:self];
}

- (void)collectionView:(UICollectionView*)collectionView didEndDisplayingCell:(UICollectionViewCell*)cell forItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* containerCell = (id)cell;
    [containerCell.viewController willMoveToParentViewController:nil];
    [containerCell.viewController removeFromParentViewController];
}

- (void)collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = (WMFArticleViewControllerContainerCell*)[collectionView cellForItemAtIndexPath:indexPath];

    WMFArticleViewController* vc = [self.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([WMFArticleViewController class])];
    vc.article         = cell.viewController.article;
    vc.contentTopInset = 64.0;

    self.cardTransition                             = [WMFArticleCardTranstion new];
    self.cardTransition.nonInteractiveDuration      = 0.5;
    self.cardTransition.offsetOfNextOverlappingCard = self.stackedLayout.topReveal;
    self.cardTransition.movingCardView              = cell;
    self.cardTransition.presentCardOffset           = vc.contentTopInset;
    vc.transitioningDelegate                        = self.cardTransition;
    vc.modalPresentationStyle                       = UIModalPresentationCustom;

    [self presentViewController:vc animated:YES completion:NULL];
}

#pragma mark - TGLStackedLayoutDelegate

- (BOOL)stackLayout:(TGLStackedLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath {
    return NO;
}

- (BOOL)stackLayout:(TGLStackedLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self.dataSource canDeleteItemAtIndexpath:indexPath];
}

- (void)stackLayout:(TGLStackedLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath {
    [self.dataSource deleteArticleAtIndexPath:indexPath];
}

@end
