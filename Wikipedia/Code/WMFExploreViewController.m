
#import "WMFExploreViewController.h"

#import "BlocksKit+UIKit.h"
#import "Wikipedia-Swift.h"

#import "WMFContentGroupDataStore.h"
#import "MWKDataStore.h"
#import "WMFArticlePreviewDataStore.h"
#import "MWKLanguageLinkController.h"

#import "WMFLocationManager.h"
#import "CLLocation+WMFBearing.h"

#import "WMFRelatedPagesContentSource.h"
#import "WMFMainPageContentSource.h"
#import "WMFNearbyContentSource.h"
#import "WMFContinueReadingContentSource.h"

#import "WMFContentGroup+WMFFeedContentDisplaying.h"
#import "WMFArticlePreview.h"
#import "MWKHistoryEntry.h"

#import "WMFDataSource.h"

#import "WMFSaveButtonController.h"

#import "WMFColumnarCollectionViewLayout.h"

#import "UIFont+WMFStyle.h"
#import "UIViewController+WMFEmptyView.h"
#import "UIView+WMFDefaultNib.h"

#import "WMFExploreSectionHeader.h"
#import "WMFExploreSectionFooter.h"

#import "WMFArticleListCollectionViewCell.h"
#import "WMFArticlePreviewCollectionViewCell.h"
#import "WMFPicOfTheDayCollectionViewCell.h"
#import "WMFNearbyArticleCollectionViewCell.h"

#import "UIViewController+WMFArticlePresentation.h"
#import "UIViewController+WMFSearch.h"

#import "WMFArticleViewController.h"
#import "WMFImageGalleryViewController.h"
#import "WMFMorePageListViewController.h"
#import "WMFSettingsViewController.h"



NS_ASSUME_NONNULL_BEGIN

static NSString *const WMFFeedEmptyFooterReuseIdentifier = @"WMFFeedEmptyFooterReuseIdentifier";

@interface WMFExploreViewController ()<WMFLocationManagerDelegate, WMFDataSourceDelegate, WMFColumnarCollectionViewLayoutDelegate>

@property (nonatomic, strong) WMFLocationManager *locationManager;

@property (nonatomic, strong) NSArray<id<WMFContentSource>>* contentSources;

@property (nonatomic, strong) id<WMFDataSource> sectionDataSource;

@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation WMFExploreViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b adjustsImageWhenHighlighted];
        UIImage *w = [UIImage imageNamed:@"W"];
        [b setImage:w forState:UIControlStateNormal];
        [b sizeToFit];
        @weakify(self);
        [b bk_addEventHandler:^(id sender) {
            @strongify(self);
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        }
             forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.titleView = b;
        self.navigationItem.titleView.isAccessibilityElement = YES;
        self.navigationItem.titleView.accessibilityLabel = MWLocalizedString(@"home-accessibility-label", nil);
        self.navigationItem.titleView.accessibilityTraits |= UIAccessibilityTraitHeader;
        self.navigationItem.leftBarButtonItem = [self settingsBarButtonItem];
        self.navigationItem.rightBarButtonItem = [self wmf_searchBarButtonItem];
    }
    return self;
}

#pragma mark - Accessors

- (UIBarButtonItem *)settingsBarButtonItem {
    return [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"]
                                            style:UIBarButtonItemStylePlain
                                           target:self
                                           action:@selector(didTapSettingsButton:)];
}

- (MWKSavedPageList *)savedPages {
    NSParameterAssert(self.userStore);
    return self.userStore.savedPageList;
}

- (MWKHistoryList *)history {
    NSParameterAssert(self.userStore);
    return self.userStore.historyList;
}

- (WMFLocationManager*)locationManager{
    if(!_locationManager){
        _locationManager = [WMFLocationManager fineLocationManager];
        _locationManager.delegate = self;
    }
    return _locationManager;
}

- (NSArray<id<WMFContentSource>>*)contentSources{
    NSParameterAssert(self.contentStore);
    NSParameterAssert(self.userStore);
    NSParameterAssert(self.previewStore);
    NSParameterAssert([self currentSiteURL]);
    if(!_contentSources){
        _contentSources = @[
                            [[WMFRelatedPagesContentSource alloc] initWithContentGroupDataStore:self.contentStore userDataStore:self.userStore articlePreviewDataStore:self.previewStore],
                            
                            [[WMFMainPageContentSource alloc] initWithSiteURL:[self currentSiteURL] contentGroupDataStore:self.contentStore articlePreviewDataStore:self.previewStore],
                            [[WMFContinueReadingContentSource alloc] initWithContentGroupDataStore:self.contentStore userDataStore:self.userStore articlePreviewDataStore:self.previewStore],
                            
                            [[WMFNearbyContentSource alloc] initWithSiteURL:[self currentSiteURL] contentGroupDataStore:self.contentStore articlePreviewDataStore:self.previewStore]];
    }
    return _contentSources;
}

- (id<WMFDataSource>)sectionDataSource{
    NSParameterAssert(self.contentStore);
    if(!_sectionDataSource){
        _sectionDataSource = [self.contentStore contentGroupDataSource];
        _sectionDataSource.granularDelegateCallbacksEnabled = YES;
    }
    return _sectionDataSource;
}

- (NSURL*)currentSiteURL{
    return [[[MWKLanguageLinkController sharedInstance] appLanguage] siteURL];
}

- (NSUInteger)numberOfSectionsInExploreFeed {
    return [self.sectionDataSource numberOfItems];
}

#pragma mark - Actions

- (void)didTapSettingsButton:(UIBarButtonItem *)sender {
    [self showSettings];
}

- (void)showSettings {
    UINavigationController *settingsContainer =
    [[UINavigationController alloc] initWithRootViewController:
     [WMFSettingsViewController settingsViewControllerWithDataStore:self.userStore previewStore:self.previewStore]];
    [self presentViewController:settingsContainer
                       animated:YES
                     completion:nil];
}

#pragma mark - Feed Sources

- (void)startContentSources{
    //if we are creating them, lets load todays data
    if(!_contentSources){
        [self updateFeedSources];
    }
    [self.contentSources makeObjectsPerformSelector:@selector(startUpdating)];
}

- (void)stopContentSources{
    [self.contentSources makeObjectsPerformSelector:@selector(stopUpdating)];
}

- (void)updateFeedSources{
    WMFTaskGroup* group = [WMFTaskGroup new];
    [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [group enter];
        [obj loadNewContentForce:NO completion:^{
            [group leave];
        }];
    }];
    
    [group waitInBackgroundWithCompletion:^{
        [self resetRefreshControl];
    }];
}

#pragma mark - Section Access

- (WMFContentGroup*)sectionAtIndex:(NSUInteger)sectionIndex{
    return [self.sectionDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:sectionIndex inSection:0]];
}

- (WMFContentGroup*)sectionForIndexPath:(NSIndexPath*)indexPath{
    return [self.sectionDataSource objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.section inSection:0]];
}

#pragma mark - Content Access

- (nullable NSArray<id>*)contentForSectionAtIndex:(NSUInteger)sectionIndex{
    WMFContentGroup* section = [self sectionAtIndex:sectionIndex];
    NSArray<id>* content = [self.contentStore contentForContentGroup:section];
    return content;
}

- (nullable NSURL*)contentURLForIndexPath:(NSIndexPath*)indexPath{
    WMFContentGroup* section = [self sectionAtIndex:indexPath.section];
    if([section contentType] != WMFContentTypeURL){
        return nil;
    }
    NSArray<NSURL*>* content = [self contentForSectionAtIndex:indexPath.section];
    if(indexPath.row >= [content count]){
        NSAssert(false, @"Attempting to reference an out of bound index");
        return nil;
    }
    return content[indexPath.row];
}

- (nullable WMFArticlePreview*)previewForIndexPath:(NSIndexPath*)indexPath{
    NSURL* url = [self contentURLForIndexPath:indexPath];
    if(url == nil){
        return nil;
    }
    return [self.previewStore itemForURL:url];
}

- (nullable MWKHistoryEntry*)userDataForIndexPath:(NSIndexPath*)indexPath{
    NSURL* url = [self contentURLForIndexPath:indexPath];
    if(url == nil){
        return nil;
    }
    return [self.userStore entryForURL:url];
}

- (nullable MWKImageInfo*)imageInfoForIndexPath:(NSIndexPath*)indexPath{
    WMFContentGroup* section = [self sectionAtIndex:indexPath.section];
    if([section contentType] != WMFContentTypeImage){
        return nil;
    }
    return [self.contentStore contentForContentGroup:section][indexPath.row];
}

#pragma mark - Refresh Control

- (NSString *)lastUpdatedString {
    //    if (!self.schemaManager.lastUpdatedAt) {
    return MWLocalizedString(@"home-last-update-never-label", nil);
    //    }
    //
    //    static NSDateFormatter *formatter;
    //    if (!formatter) {
    //        formatter = [NSDateFormatter new];
    //        formatter.dateStyle = NSDateFormatterMediumStyle;
    //        formatter.timeStyle = NSDateFormatterShortStyle;
    //    }
    //
    //    return [MWLocalizedString(@"home-last-update-label", nil) stringByReplacingOccurrencesOfString:@"$1" withString:[formatter stringFromDate:self.schemaManager.lastUpdatedAt]];
}

- (void)resetRefreshControl{
    if (![self.refreshControl isRefreshing]) {
        return;
    }
    [self.refreshControl endRefreshing];
}

#pragma mark - UIViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self wmf_orientationMaskPortraitiPhoneAnyiPad];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellsAndViews];
    self.collectionView.scrollsToTop = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl bk_addEventHandler:^(id sender) {
        [self updateFeedSources];
    }
                           forControlEvents:UIControlEventValueChanged];
    [self resetRefreshControl];
    self.sectionDataSource.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated {
    NSParameterAssert(self.contentStore);
    NSParameterAssert(self.userStore);
    [super viewDidAppear:animated];
    
    if([[NSUserDefaults wmf_userDefaults] wmf_didMigrateToNewFeed]){
        [self startContentSources];
    }else{
        WMFTaskGroup* group = [WMFTaskGroup new];
        [self.contentSources enumerateObjectsUsingBlock:^(id<WMFContentSource>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if([obj respondsToSelector:@selector(preloadContentForNumberOfDays:completion:)]){
                [group enter];
                [obj preloadContentForNumberOfDays:2 completion:^{
                    [group leave];
                }];
            }
        }];
        
        [group waitInBackgroundWithCompletion:^{
            [self startContentSources];
            [[NSUserDefaults wmf_userDefaults] wmf_setDidMigrateToNewFeed:YES];
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.sectionDataSource numberOfItems];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WMFContentGroup* contentGroup = [self sectionAtIndex:section];
    NSParameterAssert(contentGroup);
    NSArray* feedContent = [self contentForSectionAtIndex:section];
    return MIN([feedContent count], [contentGroup maxNumberOfCells]);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup* contentGroup = [self sectionForIndexPath:indexPath];
    NSParameterAssert(contentGroup);
    WMFArticlePreview* preview = [self previewForIndexPath:indexPath];
    MWKHistoryEntry* userData = [self userDataForIndexPath:indexPath];
    
    switch ([contentGroup displayType]) {
        case WMFFeedDisplayTypePage:{
            WMFArticleListCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureListCell:cell withPreview:preview userData:userData atIndexPath:indexPath];
            return cell;
        }
            break;
        case WMFFeedDisplayTypePageWithPreview:{
            WMFArticlePreviewCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePreviewCell:cell withSection:contentGroup preview:preview userData:userData atIndexPath:indexPath];
            return cell;
        }
            break;
        case WMFFeedDisplayTypePageWithLocation:{
            WMFNearbyArticleCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configureNearbyCell:cell withPreview:preview userData:userData atIndexPath:indexPath];
            return cell;
            
        }
            break;
        case WMFFeedDisplayTypePhoto:{
            MWKImageInfo* imageInfo = [self imageInfoForIndexPath:indexPath];
            WMFPicOfTheDayCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName] forIndexPath:indexPath];
            [self configurePhotoCell:cell withImageInfo:imageInfo atIndexPath:indexPath];
            return cell;
        }
            break;
        case WMFFeedDisplayTypeStory:{
            NSAssert(false, @"Unknown Display Type");
            return nil;
        }
            break;
            
        default:
            NSAssert(false, @"Unknown Display Type");
            return nil;
            break;
    }
}

- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView viewForSectionHeaderAtIndexPath:indexPath];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView viewForSectionFooterAtIndexPath:indexPath];
    } else {
        NSAssert(false, @"Unknown Supplementary View Type");
        return [UICollectionReusableView new];
    }
}


#pragma mark - UICollectionViewDelegate

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForItemAtIndexPath:(NSIndexPath *)indexPath forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup* section = [self sectionAtIndex:indexPath.section];
    
    switch ([section displayType]) {
        case WMFFeedDisplayTypePage:{
            return [WMFArticleListCollectionViewCell estimatedRowHeight];
        }
            break;
        case WMFFeedDisplayTypePageWithPreview:{
            return [WMFArticlePreviewCollectionViewCell estimatedRowHeight];
        }
            break;
        case WMFFeedDisplayTypePageWithLocation:{
            return [WMFNearbyArticleCollectionViewCell estimatedRowHeight];
        }
            break;
        case WMFFeedDisplayTypePhoto:{
            return [WMFPicOfTheDayCollectionViewCell estimatedRowHeight];
        }
            break;
        case WMFFeedDisplayTypeStory:{
            NSAssert(false, @"Unknown Content Type");
            return [WMFArticleListCollectionViewCell estimatedRowHeight];
        }
            break;
            
        default:
            NSAssert(false, @"Unknown Content Type");
            return [WMFArticleListCollectionViewCell estimatedRowHeight];
            break;
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForHeaderInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    return 66;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView estimatedHeightForFooterInSection:(NSInteger)section forColumnWidth:(CGFloat)columnWidth {
    WMFContentGroup* sectionObject = [self sectionAtIndex:section];
    if([sectionObject moreType] == WMFFeedMoreTypeNone){
        return 0.0;
    }else{
        return 50.0;
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView prefersWiderColumnForSectionAtIndex:(NSUInteger)index {
    WMFContentGroup* section = [self sectionAtIndex:index];
    return [section prefersWiderColumn];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    
    if([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]] || [self isDisplayingLocationCell]){
        [self.locationManager startMonitoringLocation];
    }else{
        [self.locationManager stopMonitoringLocation];
    }
//    WMFContentGroup* section = [self sectionAtIndex:indexPath.section];
//    if ([controller conformsToProtocol:@protocol(WMFAnalyticsContentTypeProviding)]) {
//        [[PiwikTracker wmf_configuredInstance] wmf_logActionImpressionInContext:self contentType:section];
//    }
    
}


- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionHeaderAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup* section = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(section);
    WMFExploreSectionHeader *header = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName] forIndexPath:indexPath];
    
    header.image = [[section headerIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    header.imageTintColor = [section headerIconTintColor];
    header.imageBackgroundColor = [section headerIconBackgroundColor];
    
    NSMutableAttributedString *title = [[section headerTitle] mutableCopy];
    [title addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderTitleFont] range:NSMakeRange(0, title.length)];
    header.title = title;
    
    NSMutableAttributedString *subTitle = [[section headerSubTitle] mutableCopy];
    [subTitle addAttribute:NSFontAttributeName value:[UIFont wmf_exploreSectionHeaderSubTitleFont] range:NSMakeRange(0, subTitle.length)];
    header.subTitle = subTitle;
    
    @weakify(self);
    header.whenTapped = ^{
        @strongify(self);
        [self didTapHeaderInSection:indexPath.section];
    };
    //
    //    if ([controller conformsToProtocol:@protocol(WMFHeaderMenuProviding)]) {
    //        header.rightButtonEnabled = YES;
    //        [[header rightButton] setImage:[UIImage imageNamed:@"overflow-mini"] forState:UIControlStateNormal];
    //        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    //        @weakify(controller);
    //        [header.rightButton bk_addEventHandler:^(id sender) {
    //            @strongify(controller);
    //            @strongify(self);
    //            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    //                UIAlertController *menuActionSheet = [(id<WMFHeaderMenuProviding>)controller menuActionSheet];
    //                menuActionSheet.modalPresentationStyle = UIModalPresentationPopover;
    //                menuActionSheet.popoverPresentationController.sourceView = sender;
    //                menuActionSheet.popoverPresentationController.sourceRect = [sender bounds];
    //                menuActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    //                [self presentViewController:menuActionSheet animated:YES completion:nil];
    //            } else {
    //                UIAlertController *menuActionSheet = [(id<WMFHeaderMenuProviding>)controller menuActionSheet];
    //                menuActionSheet.popoverPresentationController.sourceView = self.navigationController.tabBarController.tabBar.superview;
    //                menuActionSheet.popoverPresentationController.sourceRect = self.navigationController.tabBarController.tabBar.frame;
    //                [self presentViewController:menuActionSheet animated:YES completion:nil];
    //            }
    //        }
    //                              forControlEvents:UIControlEventTouchUpInside];
    //    } else if ([controller conformsToProtocol:@protocol(WMFHeaderActionProviding)] && (![controller respondsToSelector:@selector(isHeaderActionEnabled)] || [(id<WMFHeaderActionProviding>)controller isHeaderActionEnabled])) {
    //        header.rightButtonEnabled = YES;
    //        [[header rightButton] setImage:[(id<WMFHeaderActionProviding>)controller headerButtonIcon] forState:UIControlStateNormal];
    //        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    //        @weakify(controller);
    //        [header.rightButton bk_addEventHandler:^(id sender) {
    //            @strongify(controller);
    //            [(id<WMFHeaderActionProviding>)controller performHeaderButtonAction];
    //        }
    //                              forControlEvents:UIControlEventTouchUpInside];
    //    } else {
    //        header.rightButtonEnabled = NO;
    //        [header.rightButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];
    //    }
    
    return header;
}
//
//#pragma mark - WMFHeaderMenuProviding
//
//- (UIAlertController *)menuActionSheet {
//    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//    [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"home-hide-suggestion-prompt", nil)
//                                              style:UIAlertActionStyleDestructive
//                                            handler:^(UIAlertAction *_Nonnull action) {
//                                                [self.blackList addBlackListArticleURL:self.url];
//                                            }]];
//    [sheet addAction:[UIAlertAction actionWithTitle:MWLocalizedString(@"home-hide-suggestion-cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
//    return sheet;
//}


- (nonnull UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSectionFooterAtIndexPath:(NSIndexPath *)indexPath {
    WMFContentGroup* group = [self sectionAtIndex:indexPath.section];
    NSParameterAssert(group);
    
    if([group moreType] == WMFFeedMoreTypeNone){
        return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyFooterReuseIdentifier forIndexPath:indexPath];
    }
    
    WMFExploreSectionFooter *footer = (id)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName] forIndexPath:indexPath];
    footer.visibleBackgroundView.alpha = 1.0;
    footer.moreLabel.text = [group footerText];
    footer.moreLabel.textColor = [UIColor wmf_exploreSectionFooterTextColor];
    @weakify(self);
    footer.whenTapped = ^{
        @strongify(self);
        [self presentMoreViewControllerForSectionAtIndex:indexPath.section animated:YES];
    };
    return footer;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    [self presentDetailViewControllerForItemAtIndexPath:indexPath animated:YES];
    
}


#pragma mark - Cells, Headers and Footers

- (void)registerCellsAndViews{
    
    [self.collectionView registerNib:[WMFExploreSectionHeader wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:[WMFExploreSectionHeader wmf_nibName]];
    
    [self.collectionView registerNib:[WMFExploreSectionFooter wmf_classNib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:[WMFExploreSectionFooter wmf_nibName]];
    
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WMFFeedEmptyFooterReuseIdentifier];
    
    [self.collectionView registerNib:[WMFArticleListCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticleListCollectionViewCell wmf_nibName]];
    
    [self.collectionView registerNib:[WMFArticlePreviewCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCollectionViewCell wmf_nibName]];
    
    [self.collectionView registerNib:[WMFNearbyArticleCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFNearbyArticleCollectionViewCell wmf_nibName]];
    
    [self.collectionView registerNib:[WMFPicOfTheDayCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFPicOfTheDayCollectionViewCell wmf_nibName]];
}

- (void)configureListCell:(WMFArticleListCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry*)userData atIndexPath:(NSIndexPath *)indexPath{
    cell.titleText = preview.displayTitle;
    cell.titleLabel.accessibilityLanguage = userData.url.wmf_language;
    cell.descriptionText = preview.wikidataDescription;
    [cell setImageURL:preview.thumbnailURL];
}


- (void)configurePreviewCell:(WMFArticlePreviewCollectionViewCell *)cell withSection:(WMFContentGroup*)section preview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry*)userData atIndexPath:(NSIndexPath *)indexPath{
    cell.titleText = preview.displayTitle;
    cell.descriptionText = preview.wikidataDescription;
    cell.snippetText = preview.snippet;
    [cell setImageURL:preview.thumbnailURL];
    [cell setSaveableURL:preview.url savedPageList:self.userStore.savedPageList];
    cell.saveButtonController.analyticsContext = [self analyticsContext];
    cell.saveButtonController.analyticsContentType = [section analyticsContentType];
}

- (void)configureNearbyCell:(WMFNearbyArticleCollectionViewCell *)cell withPreview:(WMFArticlePreview *)preview userData:(MWKHistoryEntry*)userData atIndexPath:(NSIndexPath *)indexPath{
    cell.titleText = preview.displayTitle;
    cell.descriptionText = [preview.wikidataDescription wmf_stringByCapitalizingFirstCharacter];
    [cell setImageURL:preview.thumbnailURL];
    [self updateLocationCell:cell location:preview.location];
}

- (void)configurePhotoCell:(WMFPicOfTheDayCollectionViewCell *)cell withImageInfo:(MWKImageInfo *)imageInfo atIndexPath:(NSIndexPath *)indexPath{
    [cell setImageURL:imageInfo.imageThumbURL];
    if (imageInfo.imageDescription.length) {
        [cell setDisplayTitle:imageInfo.imageDescription];
    } else {
        [cell setDisplayTitle:imageInfo.canonicalPageTitle];
    }
    //    self.referenceImageView = cell.potdImageView;
}

- (BOOL)isDisplayingLocationCell{
    __block BOOL hasLocationCell = NO;
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]){
            hasLocationCell = YES;
            *stop = YES;
        }
        
    }];
    return hasLocationCell;
}

- (void)updateLocationCells{
    [[self.collectionView indexPathsForVisibleItems] enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UICollectionViewCell* cell = [self.collectionView cellForItemAtIndexPath:obj];
        if([cell isKindOfClass:[WMFNearbyArticleCollectionViewCell class]]){
            WMFArticlePreview* preview = [self previewForIndexPath:obj];
            [self updateLocationCell:(WMFNearbyArticleCollectionViewCell*)cell location:preview.location];
        }
    }];
}

- (void)updateLocationCell:(WMFNearbyArticleCollectionViewCell*)cell location:(CLLocation*)location{
    [cell setDistance:[self.locationManager.location distanceFromLocation:location]];
    [cell setBearing:[self.locationManager.location wmf_bearingToLocation:location forCurrentHeading:self.locationManager.heading]];
    
}

- (void)selectItem:(NSUInteger)item inSection:(NSUInteger)section {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}



#pragma mark - Header Action


- (void)didTapHeaderInSection:(NSUInteger)section {
    WMFContentGroup* group = [self sectionAtIndex:section];
    
    switch ([group headerActionType]) {
        case WMFFeedHeaderActionTypeOpenHeaderContent:{
            NSURL* url = [group headerContentURL];
            [self wmf_pushArticleWithURL:url dataStore:self.userStore previewStore:self.previewStore animated:YES];
        }
            break;
        case WMFFeedHeaderActionTypeOpenFirstItem:{
            [self selectItem:0 inSection:section];
        }
            break;
        case WMFFeedHeaderActionTypeOpenMore:{
            [self presentMoreViewControllerForSectionAtIndex:section animated:YES];
        }
            break;
        default:
            NSAssert(false, @"Unknown header action");
            break;
    }
}



#pragma mark - More View Controller

- (void)presentMoreViewControllerForSectionAtIndex:(NSUInteger)sectionIndex animated:(BOOL)animated {
    WMFContentGroup* group = [self sectionAtIndex:sectionIndex];
    //    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughMoreInContext:self contentType:controllerForSection];
    NSArray<NSURL*>* URLs = [self contentForSectionAtIndex:sectionIndex];
    
    switch (group.moreType) {
        case WMFFeedMoreTypePageList:
        {
            WMFMorePageListViewController* vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypeNormal;
            [self.navigationController pushViewController:vc animated:animated];
        }
            break;
        case WMFFeedMoreTypePageListWithPreview:
        {
            WMFMorePageListViewController* vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypePreview;
            [self.navigationController pushViewController:vc animated:animated];
        }
            break;
        case WMFFeedMoreTypePageListWithLocation:
        {
            WMFMorePageListViewController* vc = [[WMFMorePageListViewController alloc] initWithGroup:group articleURLs:URLs userDataStore:self.userStore previewStore:self.previewStore];
            vc.cellType = WMFMorePageListCellTypeLocation;
            [self.navigationController pushViewController:vc animated:animated];
        }
            break;
        case WMFFeedMoreTypePageWithRandomButton:
        {
            
            
        }
            break;
            
        default:
            NSAssert(false, @"Unknown More Type");
            break;
    }
    
}


#pragma mark - Detail View Controller

- (void)presentDetailViewControllerForItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
    WMFContentGroup* group = [self sectionAtIndex:indexPath.section];
    //    [[PiwikTracker wmf_configuredInstance] wmf_logActionTapThroughInContext:self contentType:group.contentType];
    
    switch ([group detailType]) {
        case WMFFeedDetailTypePage:{
            NSURL *url = [self contentURLForIndexPath:indexPath];
            [self wmf_pushArticleWithURL:url dataStore:self.userStore previewStore:self.previewStore animated:animated];
        }
            break;
        case WMFFeedDetailTypePageWithRandomButton:{
        }
            break;
        case WMFFeedDetailTypeGallery:{
            MWKImageInfo* image = [self imageInfoForIndexPath:indexPath];
            WMFPOTDImageGalleryViewController *vc = [[WMFPOTDImageGalleryViewController alloc] initWithDates:@[group.date] selectedImageInfo:image];
            [self presentViewController:vc animated:animated completion:nil];
        }
            break;
        default:
            NSAssert(false, @"Unknown Detail Type");
            break;
    }
}

#pragma mark - WMFDataSourceDelegate

- (void)dataSourceDidUpdateAllData:(id<WMFDataSource>)dataSource{
    [self.collectionView reloadData];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteSectionsAtIndexes:(NSIndexSet *)indexes{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteSections:indexes];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didInsertSectionsAtIndexes:(NSIndexSet *)indexes{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView insertSections:indexes];
    //    } completion:NULL];
}

- (void)dataSource:(id<WMFDataSource>)dataSource didDeleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didInsertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView insertItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didMoveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView deleteItemsAtIndexPaths:@[fromIndexPath]];
    //        [self.collectionView insertItemsAtIndexPaths:@[toIndexPath]];
    //    } completion:NULL];
}
- (void)dataSource:(id<WMFDataSource>)dataSource didUpdateRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths{
    [self.collectionView reloadData];
    //    [self.collectionView performBatchUpdates:^{
    //        [self.collectionView reloadItemsAtIndexPaths:indexPaths];
    //    } completion:NULL];
}

#pragma mark - WMFLocationManager

- (void)locationManager:(WMFLocationManager *)controller didUpdateLocation:(CLLocation *)location {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didUpdateHeading:(CLHeading *)heading {
    [self updateLocationCells];
}

- (void)locationManager:(WMFLocationManager *)controller didReceiveError:(NSError *)error {
    //TODO: probably not displaying the error, but maybe?
}

#pragma mark - Analytics

- (NSString *)analyticsContext {
    return @"Explore";
}

- (NSString *)analyticsName {
    return [self analyticsContext];
}



@end


NS_ASSUME_NONNULL_END
