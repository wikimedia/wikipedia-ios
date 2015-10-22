//
//  WMFRandomSectionController.m
//  Wikipedia
//
//  Created by Corey Floyd on 10/22/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFRandomSectionController.h"
#import "WMFRandomArticleFetcher.h"

#import "MWKSite.h"
#import "MWKSavedPageList.h"

#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"


static NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong) NSDictionary* result;

@end

@implementation WMFRandomSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site {
    NSParameterAssert(site);
    self = [super init];
    if (self) {
        self.searchSite = site;
    }
    return self;
}

- (void)setSavedPageList:(MWKSavedPageList*)savedPageList {
    /*
       HAX: can't fetch titles until we get the saved page list, since it's needed to create articles
       and configure cells
     */
    _savedPageList = savedPageList;
    [self getNewRandomArticle];
}

- (WMFRandomArticleFetcher*)fetcher {
    if (_fetcher == nil) {
        _fetcher = [[WMFRandomArticleFetcher alloc] init];
    }
    return _fetcher;
}

- (id)sectionIdentifier {
    return WMFRandomSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"random-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:@"Random" attributes:nil];
}

- (UIImage*)headerButtonIcon {
    return [UIImage imageNamed:@"reload-mini"];
}

- (void)performHeaderButtonAction {
    [self getNewRandomArticle];
}

- (NSArray*)items {
    return @[self.result];
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [self.searchSite titleWithString:self.result[@"title"]];
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFArticlePreviewCell wmf_classNib] forCellWithReuseIdentifier:[WMFArticlePreviewCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFArticlePreviewCell cellForCollectionView:collectionView indexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFArticlePreviewCell class]]) {
        WMFArticlePreviewCell* previewCell = (id)cell;
//        MWKRelatedSearchResult* result     = object;
//        previewCell.title           = [self titleForItemAtIndex:indexPath.row];
//        previewCell.descriptionText = result.wikidataDescription;
//        previewCell.imageURL        = result.thumbnailURL;
//        [previewCell setSummary:result.extract];
        [previewCell setSavedPageList:self.savedPageList];
    }
}

- (void)getNewRandomArticle {
    if (self.fetcher.isFetching) {
        return;
    }
    @weakify(self);
    [self.fetcher fetchRandomArticleWithSite:self.searchSite]
    .then(^(id result){
        @strongify(self);
        self.result = result;
        [self.delegate controller:self didSetItems:self.items];
    })
    .catch(^(NSError* error){
    });
}

@end
