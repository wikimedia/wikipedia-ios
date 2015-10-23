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
#import "MWKSearchResult.h"

#import "WMFArticlePreviewCell.h"
#import "UIView+WMFDefaultNib.h"


static NSString* const WMFRandomSectionIdentifier = @"WMFRandomSectionIdentifier";

@interface WMFRandomSectionController ()

@property (nonatomic, strong, readwrite) MWKSite* searchSite;
@property (nonatomic, strong) MWKSavedPageList* savedPageList;
@property (nonatomic, strong) WMFRandomArticleFetcher* fetcher;

@property (nonatomic, strong) MWKSearchResult* result;

@end

@implementation WMFRandomSectionController

@synthesize delegate = _delegate;

- (instancetype)initWithSite:(MWKSite*)site savedPageList:(MWKSavedPageList*)savedPageList {
    NSParameterAssert(site);
    NSParameterAssert(savedPageList);
    self = [super init];
    if (self) {
        self.searchSite    = site;
        self.savedPageList = savedPageList;
        [self getNewRandomArticle];
    }
    return self;
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
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"main-menu-random", nil) attributes:nil];
}

- (UIImage*)headerButtonIcon {
    return [UIImage imageNamed:@"reload-mini"];
}

- (void)performHeaderButtonAction {
    [self getNewRandomArticle];
}

- (NSArray*)items {
    if (self.result) {
        return @[self.result];
    } else {
        return nil;
    }
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return [self.searchSite titleWithString:self.result.displayTitle];
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
        MWKSearchResult* result            = object;
        previewCell.title           = [self titleForItemAtIndex:indexPath.row];
        previewCell.descriptionText = result.wikidataDescription;
        previewCell.imageURL        = result.thumbnailURL;
        [previewCell setSummary:result.extract];
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
