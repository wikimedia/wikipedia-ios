
#import "WMFFeedViewController.h"

#import "WMFFeedDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKLanguageLinkController.h"

#import "WMFMoreLikeFeedSource.h"
#import "WMFMainPageFeedSource.h"

#import "WMFDataSource.h"

#import "WMFMainPageFeedSectionController.h"

#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"

#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"
#import "WMFArticleListCollectionViewCell.h"
#import "WMFArticlePreviewCollectionViewCell.h"


#import "WMFRelatedTitleViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface WMFFeedViewController ()

@property (nonatomic, strong) NSArray<id<WMFFeedSource>>* feedSources;

@property (nonatomic, strong) NSMutableDictionary<NSString*, Class>* cellIdentifier;


@property (nonatomic, strong) id<WMFDataSource> sectionDataSource;

@end

@implementation WMFFeedViewController

#pragma mark - Accessors

- (MWKSavedPageList *)savedPages {
    NSParameterAssert(self.userStore);
    return self.userStore.savedPageList;
}

- (MWKHistoryList *)history {
    NSParameterAssert(self.userStore);
    return self.userStore.historyList;
}

- (NSArray<id<WMFFeedSource>>*)feedSources{
    NSParameterAssert(self.feedStore);
    NSParameterAssert(self.userStore);
    NSParameterAssert(self.previewStore);
    if(!_feedSources){
        _feedSources = @[[[WMFMoreLikeFeedSource alloc] initWithFeedDataStore:self.feedStore userDataStore:self.userStore articlePreviewDataStore:self.previewStore],
                         [[WMFMainPageFeedSource alloc] initWithSiteURL:[self currentSiteURL] feedDataStore:self.feedStore articlePreviewDataStore:self.previewStore]];
    }
    return _feedSources;
}

- (id<WMFDataSource>)sectionDataSource{
    NSParameterAssert(self.feedStore);
    if(!_sectionDataSource){
        _sectionDataSource = [self.feedStore feedDataSource];
    }
    return _sectionDataSource;
}

- (NSURL*)currentSiteURL{
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

- (id<WMFFeedSectionControlling>)contentManagerForSection:(WMFExploreSection*)section{
    
    switch (section.type) {
        case WMFExploreSectionTypeMainPage:
        {
            
        }
            break;
        case WMFExploreSectionTypeSaved:
        case WMFExploreSectionTypeHistory:
        {
            return <#expression#>
        }
            break;
            
        default:
            return nil;
            break;
    }

    
    
}


#pragma mark - Feed Sources

- (void)startFeedSources{
    [self.feedSources makeObjectsPerformSelector:@selector(startUpdating)];
}

- (void)stopFeedSources{
    [self.feedSources makeObjectsPerformSelector:@selector(stopUpdating)];
}

#pragma mark - UIViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellsAndViews];
    self.collectionView.scrollsToTop = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self startFeedSources];
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.feedStore);
    NSParameterAssert(self.userStore);
    [super viewDidAppear:animated];
    [self startFeedSources];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.sectionDataSource numberOfItems];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSArray* feedContent = [self.sectionDataSource metadataAtIndexPath:[NSIndexPath indexPathForRow:section inSection:0]];
    return [feedContent count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    
    return cell;
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView viewForSectionHeaderAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView viewForSectionFooterAtIndexPath:indexPath];
    } else {
        assert(false);
        return [UICollectionReusableView new];
    }
}


#pragma mark - UICollectionViewDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    WMFExploreSection* section = [self sectionAtIndex:indexPath.section];
    

    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    NSParameterAssert(controller);
    return [controller estimatedRowHeight];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    return 66;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFExploreSection* sectionObject = [self sectionAtIndex:section];
    
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:section];
    
    if (!controller) {
        return 0;
    }
    
    if ([controller conformsToProtocol:@protocol(WMFMoreFooterProviding)] && (![controller respondsToSelector:@selector(isFooterEnabled)] || [(id<WMFMoreFooterProviding>)controller isFooterEnabled])) {
        return 50;
    } else {
        return 0;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index {
    WMFExploreSection* section = [self sectionAtIndex:indexPath.section];

    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:index];
    return [controller respondsToSelector:@selector(prefersWiderColumn)] && [controller prefersWiderColumn];
}


#pragma mark - Cells, Headers and Footers

- (void)registerCellsAndViews{
    
    [self.collectionView registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];
    
    [self.collectionView registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];
    
    [self.collectionView registerNib:[WMFArticleListCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticleListCollectionViewCell identifier]];
    
    [self.collectionView registerNib:[WMFArticlePreviewCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell identifier]];

}

- (CGFloat)estimatedSizeForCellIdentifier:(NSString*)cellIdentifier{
    if([cellIdentifier isEqualToString:[WMFArticleListCollectionViewCell identifier]]){
        return [WMFArticleListCollectionViewCell estimatedRowHeight];
    }else if([cellIdentifier isEqualToString:[WMFArticlePreviewCollectionViewCell identifier]]){
        return [WMFArticlePreviewCollectionViewCell estimatedRowHeight];
    }else{
        return 0.0;
    }
}

- (void)configureListCell:(WMFArticleListCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry*)userData atIndexPath:(NSIndexPath *)indexPath{
    cell.titleText = preview.displayTitle;
    cell.titleLabel.accessibilityLanguage = userData.url.wmf_language;
    cell.descriptionText = preview.wikidataDescription;
    [cell setImageURL:preview.thumbnailURL];
}


- (void)configurePreviewCell:(WMFArticlePreviewCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry*)userData atIndexPath:(NSIndexPath *)indexPath{
    cell.titleText = preview.displayTitle;
    cell.descriptionText = preview.wikidataDescription;
    cell.snippetText = preview.snippet;
    [cell setImageURL:preview.thumbnailURL];
    [cell setSaveableURL:preview.url savedPageList:self.savedPageList];
    cell.saveButtonController.analyticsContext = self;
    cell.saveButtonController.analyticsContentType = self;
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    
    if (!controller) {
        return nil;
    }
    
    WMFExploreSectionHeader *header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];
    
    [self configureHeader:header withStylingFromController:controller];
    
    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:indexPath.section];
    };
    
    if ([controller conformsToProtocol:@protocol(WMFHeaderMenuProviding)]) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        @weakify(controller);
        [header.rightButton bk_addEventHandler:^(id sender) {
            @strongify(controller);
            @strongify(self);
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
                UIAlertController *menuActionSheet = [(id<WMFHeaderMenuProviding>)controller menuActionSheet];
                menuActionSheet.modalPresentationStyle = UIModalPresentationPopover;
                menuActionSheet.popoverPresentationController.sourceView = sender;
                menuActionSheet.popoverPresentationController.sourceRect = [sender bounds];
                menuActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            } else {
                UIAlertController *menuActionSheet = [(id<WMFHeaderMenuProviding>)controller menuActionSheet];
                menuActionSheet.popoverPresentationController.sourceView = self.navigationController.tabBarController.tabBar.superview;
                menuActionSheet.popoverPresentationController.sourceRect = self.navigationController.tabBarController.tabBar.frame;
                [self presentViewController:menuActionSheet animated:YES completion:nil];
            }
        }
                              forControlEvents:UIControlEventTouchUpInside];
    } else if ([controller conformsToProtocol:@protocol(WMFHeaderActionProviding)] && (![controller respondsToSelector:@selector(isHeaderActionEnabled)] || [(id<WMFHeaderActionProviding>)controller isHeaderActionEnabled])) {
        header.rightButtonEnabled = YES;
        [[header rightButton] setImage:[(id<WMFHeaderActionProviding>)controller headerButtonIcon] forState:UIControlStateNormal];
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
        @weakify(controller);
        [header.rightButton bk_addEventHandler:^(id sender) {
            @strongify(controller);
            [(id<WMFHeaderActionProviding>)controller performHeaderButtonAction];
        }
                              forControlEvents:UIControlEventTouchUpInside];
    } else {
        header.rightButtonEnabled = NO;
        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    }
    
    return header;
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    id<WMFExploreSectionController> controller = [self sectionControllerForSectionAtIndex:indexPath.section];
    if (!controller) {
        return nil;
    }
    
    if ([controller conformsToProtocol:@protocol(WMFMoreFooterProviding)] && (![controller respondsToSelector:@selector(isFooterEnabled)] || [(id<WMFMoreFooterProviding>)controller isFooterEnabled])) {
        WMFExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
        footer.visibleBackgroundView.alpha = 1.0;
        footer.moreLabel.text = [(id<WMFMoreFooterProviding>)controller footerText];
        footer.moreLabel.textColor = [UIColor wmf_exploreSectionFooterTextColor];
        @weakify(self);
        footer.whenTapped = ^{
            @strongify(self);
            [self didTapFooterInSection:indexPath.section];
        };
        return footer;
    } else {
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFExploreEmptyFooterReuseIdentifier forIndexPath:indexPath];
    }
}

#pragma mark - Section Access

- (WMFExploreSection*)sectionAtIndex:(NSUInteger)sectionIndex{
    return [self.sectionDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:sectionIndex inSection:0]];
}


#pragma mark - More View Controller

- (nullable UIViewController *)moreViewControllerForSectionAtIndex:(NSUInteger)sectionIndex {
    WMFExploreSection* section = [self sectionAtIndex:sectionIndex];
    NSArray<NSURL*>* URLs = [self.feedStore contentURLsForSection:section];
    
    switch (section.type) {
        case WMFExploreSectionTypeMainPage:
        {
            
        }
            break;
        case WMFExploreSectionTypeSaved:
        case WMFExploreSectionTypeHistory:
        {
            return [[WMFRelatedTitleViewController alloc] initWithSection:section articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
        }
            break;
            
        default:
            return nil;
            break;
    }
    
}


#pragma mark - Detail View Controller

- (UIViewController *)detailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFExploreSection* section = [self sectionAtIndex:sectionIndex];
    NSURL *url = [self urlForItemAtIndexPath:indexPath];
    return [[WMFArticleViewController alloc] initWithArticleURL:url dataStore:self.dataStore];
}


@end


NS_ASSUME_NONNULL_END
