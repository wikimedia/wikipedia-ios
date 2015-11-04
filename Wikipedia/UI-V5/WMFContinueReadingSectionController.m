//
//  WMFContinueReadingSectionController.m
//  Wikipedia
//
//  Created by Corey Floyd on 10/7/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFContinueReadingSectionController.h"
#import "WMFContinueReadingCell.h"
#import "UIView+WMFDefaultNib.h"
#import "MWKTitle.h"
#import "MWKDataStore.h"
#import "MWKArticle.h"
#import "NSString+Extras.h"

static NSString* const WMFContinueReadingSectionIdentifier = @"WMFContinueReadingSectionIdentifier";

@interface WMFContinueReadingSectionController ()

@property (nonatomic, strong, readwrite) MWKTitle* title;
@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

@end

@implementation WMFContinueReadingSectionController
@synthesize delegate = _delegate;

- (instancetype)initWithArticleTitle:(MWKTitle*)title
                           dataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(title);
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.title     = title;
        self.dataStore = dataStore;
    }
    return self;
}

- (id)sectionIdentifier {
    return WMFContinueReadingSectionIdentifier;
}

- (UIImage*)headerIcon {
    return [UIImage imageNamed:@"home-continue-reading-mini"];
}

- (NSAttributedString*)headerText {
    return [[NSAttributedString alloc] initWithString:MWLocalizedString(@"home-continue-reading-heading", nil) attributes:nil];
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodReloadFromNetwork;
}

- (NSArray*)items {
    return @[self.title];
}

- (MWKTitle*)titleForItemAtIndex:(NSUInteger)index {
    return self.title;
}

- (void)registerCellsInCollectionView:(UICollectionView* __nonnull)collectionView {
    [collectionView registerNib:[WMFContinueReadingCell wmf_classNib] forCellWithReuseIdentifier:[WMFContinueReadingCell identifier]];
}

- (UICollectionViewCell*)dequeueCellForCollectionView:(UICollectionView*)collectionView atIndexPath:(NSIndexPath*)indexPath {
    return [WMFContinueReadingCell cellForCollectionView:collectionView indexPath:indexPath];
}

- (void)configureCell:(UICollectionViewCell*)cell
           withObject:(id)object
     inCollectionView:(UICollectionView*)collectionView
          atIndexPath:(NSIndexPath*)indexPath {
    if ([cell isKindOfClass:[WMFContinueReadingCell class]]) {
        WMFContinueReadingCell* readingCell = (id)cell;
        readingCell.title.text   = self.title.text;
        readingCell.summary.text = [[self.dataStore existingArticleWithTitle:self.title].entityDescription wmf_stringByCapitalizingFirstCharacter];
    }
}

@end
