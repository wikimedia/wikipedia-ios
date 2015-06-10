
#import "WMFArticleListCollectionViewController.h"
#import "MWKUserDataStore.h"
#import "MWKSavedPageList.h"

#import "WMFArticleViewControllerContainerCell.h"
#import "WMFArticleViewController.h"

#import "TGLStackedLayout.h"

@interface WMFArticleListCollectionViewController ()<TGLStackedLayoutDelegate>

@property (nonatomic, assign, readwrite) WMFArticleListType listType;
@property (nonatomic, strong, readonly) TGLStackedLayout* stackedLayout;

@end

@implementation WMFArticleListCollectionViewController

#pragma mark - Accessors

- (MWKSavedPageList*)savedPages {
    return [self.userDataStore savedPageList];
}

- (TGLStackedLayout*)stackedLayout{

    if([self.collectionView.collectionViewLayout isKindOfClass:[TGLStackedLayout class]]){
        return (id)self.collectionView.collectionViewLayout;
    }

    return nil;
}

#pragma mark - List Type

- (NSString*)titleForListType:(WMFArticleListType)type {
    //Do not make static so translations are always fresh
    return @{@(WMFArticleListTypeSaved): MWLocalizedString(@"saved-pages-title", nil)}[@(type)];
}

- (void)setListType:(WMFArticleListType)type animated:(BOOL)animated {
    if (self.listType == type) {
        return;
    }

    self.listType = type;
    [self.collectionView reloadData];
}

#pragma mark - Saved pages / Article Access

- (MWKSavedPageEntry*)savedPageForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self.savedPages entryAtIndex:indexPath.row];
    return savedEntry;
}

- (MWKArticle*)articleForIndexPath:(NSIndexPath*)indexPath {
    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    return [self.userDataStore.dataStore articleWithTitle:savedEntry.title];
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = [self titleForListType:self.listType];
    self.stackedLayout.fillHeight = YES;
    self.stackedLayout.alwaysBounce = YES;
    self.stackedLayout.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.stackedLayout.itemSize = CGSizeMake(self.view.bounds.size.width, 200);
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
        self.stackedLayout.itemSize = CGSizeMake(self.view.bounds.size.width, 200);
    }];

    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

// iOS 8+ Rotation Support
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {

    [coordinator animateAlongsideTransition:^(id <UIViewControllerTransitionCoordinatorContext> context)
    {
        self.stackedLayout.itemSize = CGSizeMake(self.view.bounds.size.width, 200);
    }                            completion:NULL];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
    return [[self savedPages] length];
}

- (UICollectionViewCell*)collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath {
    WMFArticleViewControllerContainerCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([WMFArticleViewControllerContainerCell class]) forIndexPath:indexPath];

    if (cell.viewController == nil) {
        [cell setViewControllerAndAddViewToContentView:[[WMFArticleViewController alloc] init]];
    }

    [self addChildViewController:cell.viewController];

    MWKArticle* article = [self articleForIndexPath:indexPath];
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

#pragma mark - TGLStackedLayoutDelegate

- (BOOL)stackLayout:(TGLStackedLayout*)layout canMoveItemAtIndexPath:(NSIndexPath*)indexPath{

    return NO;
}

- (BOOL)stackLayout:(TGLStackedLayout*)layout canDeleteItemAtIndexPath:(NSIndexPath*)indexPath{

    return YES;
}

- (void)stackLayout:(TGLStackedLayout*)layout deleteItemAtIndexPath:(NSIndexPath*)indexPath{

    MWKSavedPageEntry* savedEntry = [self savedPageForIndexPath:indexPath];
    if (savedEntry) {
        [self.savedPages removeEntry:savedEntry];
        [self.userDataStore save];

    }
}



@end
