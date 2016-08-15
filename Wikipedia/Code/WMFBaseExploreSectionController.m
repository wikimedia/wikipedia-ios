//
//  WMFBaseExploreSectionController.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/25/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseExploreSectionController.h"
#import "WMFEmptySectionCollectionViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

NS_ASSUME_NONNULL_BEGIN

static const DDLogLevel WMFBaseExploreSectionControllerLogLevel = DDLogLevelInfo;

#undef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF WMFBaseExploreSectionControllerLogLevel

static NSString *const WMFExploreSectionControllerException = @"WMFExploreSectionControllerException";

@interface WMFBaseExploreSectionController ()

@property(nonatomic, strong, readwrite) MWKDataStore *dataStore;

/**
 *  The items visible to the WMFExploreViewController
 *  May contain placeholder items
 */
@property(nonatomic, strong) NSMutableArray *mutableItems;

@property(nonatomic, strong, nullable) NSArray *fetchedItems;

@property(nonatomic, strong, nullable) AnyPromise *fetcherPromise;

@property(nonatomic, strong, readwrite, nullable) NSError *fetchError;

@end

@implementation WMFBaseExploreSectionController

#pragma mark - Init

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore {
  NSParameterAssert(dataStore);
  self = [super init];
  if (self) {
    self.dataStore = dataStore;
    self.mutableItems = [NSMutableArray array];
    [self setItemsToPlaceholdersIfSupported];
  }
  return self;
}

- (instancetype)initWithDataStore:(MWKDataStore *)dataStore items:(NSArray *)items {
  NSParameterAssert(items);
  self = [self initWithDataStore:dataStore];
  if (self) {
    [self.mutableItems setArray:items];
  }
  return self;
}

- (NSString *)description {
  NSAssert([self conformsToProtocol:@protocol(WMFExploreSectionController)],
           @"Expected subclass of %@ to conform to %@, but %@ does not.",
           [WMFBaseExploreSectionController class],
           NSStringFromProtocol(@protocol(WMFExploreSectionController)),
           [self class]);
  return [NSString stringWithFormat:@"%@ identifier = %@",
                                    [super description], [(id<WMFExploreSectionController>)self sectionIdentifier]];
}

#pragma mark - WMFBaseExploreSectionController

- (BOOL)containsPlaceholders {
  return [self.items bk_all:^BOOL(id obj) {
    return [obj isKindOfClass:[NSNumber class]];
  }];
}

- (MWKSavedPageList *)savedPageList {
  return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryList *)historyList {
  return self.dataStore.userDataStore.historyList;
}

- (NSUInteger)numberOfPlaceholderCells {
  return 3;
}

- (NSString *)cellIdentifier {
  @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                 reason:@"Method must be implemented by subclass"
                               userInfo:nil];
}

- (UINib *)cellNib {
  @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                 reason:@"Method must be implemented by subclass"
                               userInfo:nil];
}

- (nullable NSString *)placeholderCellIdentifier {
  return nil;
}

- (nullable UINib *)placeholderCellNib {
  return nil;
}

- (void)configureEmptyCell:(WMFEmptySectionCollectionViewCell *)cell {
  cell.emptyTextLabel.text = MWLocalizedString(@"home-empty-section", nil);
  [cell.reloadButton setTitle:MWLocalizedString(@"home-empty-section-check-again", nil) forState:UIControlStateNormal];
}

- (void)configureCell:(UICollectionViewCell *)cell withItem:(id)item atIndexPath:(nonnull NSIndexPath *)indexPath {
  @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                 reason:@"Method must be implemented by subclass"
                               userInfo:nil];
}

- (AnyPromise *)fetchData {
  return [AnyPromise promiseWithValue:self.items];
}

#pragma mark - WMFExploreSectionController

- (void)registerCellsInCollectionView:(UICollectionView *)collectionView {
  [collectionView registerNib:[self cellNib] forCellWithReuseIdentifier:[self cellIdentifier]];
  if ([self placeholderCellIdentifier] && [self placeholderCellNib]) {
    [collectionView registerNib:[self placeholderCellNib] forCellWithReuseIdentifier:[self placeholderCellIdentifier]];
  }
  [collectionView registerNib:[WMFEmptySectionCollectionViewCell wmf_classNib] forCellWithReuseIdentifier:[WMFEmptySectionCollectionViewCell identifier]];
}

- (NSString *)cellIdentifierForItemIndexPath:(NSIndexPath *)indexPath {
  if ([self shouldShowPlaceholderCell]) {
    return [self placeholderCellIdentifier];
  }
  if ([self shouldShowEmptyCell]) {
    return [WMFEmptySectionCollectionViewCell identifier];
  }
  return [self cellIdentifier];
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
  NSParameterAssert(indexPath);
  NSParameterAssert(cell);
  if (!cell || !indexPath) {
    return;
  }
  if ([self shouldShowPlaceholderCell]) {
    return;
  } else if ([self shouldShowEmptyCell]) {
    WMFEmptySectionCollectionViewCell *emptyCell = (id)cell;
    [emptyCell.reloadButton bk_removeEventHandlersForControlEvents:UIControlEventTouchUpInside];

    @weakify(self);
    [emptyCell.reloadButton bk_addEventHandler:^(id sender) {
      @strongify(self);
      [self resetData];
      [self fetchDataUserInitiated];
    }
                              forControlEvents:UIControlEventTouchUpInside];

    [self configureEmptyCell:emptyCell];
  } else {
    [self configureCell:cell withItem:self.items[indexPath.row] atIndexPath:indexPath];
  }
}

- (BOOL)shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  if ([self shouldShowPlaceholderCell]) {
    return NO;
  }
  if ([self shouldShowEmptyCell]) {
    return NO;
  }
  return YES;
}

- (AnyPromise *)fetchDataIfNeeded {
  return [self fetchDataIgnoreError:NO ignoreCurrentItems:NO];
}

- (AnyPromise *)fetchDataIfError {
  return [self fetchDataIgnoreError:YES ignoreCurrentItems:NO];
}

- (AnyPromise *)fetchDataUserInitiated {
  return [self fetchDataIgnoreError:YES ignoreCurrentItems:YES];
}

- (AnyPromise *)fetchDataIgnoreError:(BOOL)ignoreError ignoreCurrentItems:(BOOL)ignoreCurrentItems {
  if (!ignoreError && [self lastFetchFailed]) {
    return [AnyPromise promiseWithValue:self.fetchError];
  } else if (!ignoreCurrentItems && [self hasResults]) {
    return [AnyPromise promiseWithValue:self.items];
  } else if ([self isFetching]) {
    return [AnyPromise promiseWithValue:self.items];
  } else {
    @weakify(self);
    self.fetcherPromise = [self fetchData].then(^(NSArray *items) {
                                            @strongify(self);
                                            self.fetcherPromise = nil;
                                            self.fetchedItems = items;
                                            return self.items;
                                          })
                              .catch(^(NSError *error) {
                                @strongify(self);
                                DDLogError(@"Failed to fetch items for section %@. %@", self, error);
                                self.fetcherPromise = nil;
                                self.fetchError = error;
                                return error;
                              });
    return self.fetcherPromise;
  }
}

- (void)resetData {
  _fetchedItems = nil;
  _fetchError = nil;
  if ([self supportsPlaceholders]) {
    [self setItemsToPlaceholdersIfSupported];
  } else {
    self.items = @[];
  }
}

#pragma mark - Utility

- (void)setItemsToPlaceholdersIfSupported {
  if (![self supportsPlaceholders]) {
    return;
  }
  NSMutableArray *placeholders = [NSMutableArray array];
  for (int i = 0; i < [self numberOfPlaceholderCells]; i++) {
    [placeholders addObject:@(i)];
  }
  [self setItems:placeholders];
}

- (BOOL)supportsPlaceholders {
  BOOL supportsPlaceholders = [self numberOfPlaceholderCells];
  NSAssert(supportsPlaceholders > 0 == ([self placeholderCellNib] != nil),
           @"placeholderCellNib must be nonnull if placeholders are supported.");
  NSAssert(supportsPlaceholders > 0 == ([self placeholderCellIdentifier] != nil),
           @"placeholderCellIdentifier must be nonnull if placeholders are supported.");
  return supportsPlaceholders;
}

/**
 *  Indicates whether placeholders should be shown.
 *
 *  @note This is not the same as whether or not placeholders are supported.
 *
 *  @return @c YES if placeholder cell should be displayed, otherwise @c NO.
 */
- (BOOL)shouldShowPlaceholderCell {
  return [self supportsPlaceholders] && [self.fetchedItems count] == 0 && self.fetchError == nil;
}

- (BOOL)shouldShowEmptyCell {
  return [self.fetchedItems count] == 0 && self.fetchError;
}

- (BOOL)lastFetchFailed {
  return self.fetchError != nil;
}

- (BOOL)hasResults {
  return [self.fetchedItems count] > 0;
}

- (BOOL)isFetching {
  return self.fetcherPromise != nil;
}

#pragma mark - Items Accessors

- (void)setFetchedItems:(nullable NSArray *)fetchedItems {
  if (WMF_EQUAL(self.fetchedItems, isEqualToArray:, fetchedItems)) {
    return;
  }
  _fetchedItems = fetchedItems;
  _fetchError = nil;
  if (fetchedItems) {
    self.items = fetchedItems;
  }
}

- (void)setFetchError:(nullable NSError *)fetchError {
  _fetchError = fetchError;
  _fetchedItems = nil;
  if (fetchError) {
    self.items = @[ fetchError ];
  }
}

+ (BOOL)automaticallyNotifiesObserversOfItems {
  return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfMutableItems {
  return NO;
}

- (void)setItems:(NSArray *_Nonnull)items {
  if (WMF_EQUAL(self.items, isEqualToArray:, items)) {
    return;
  }
  // NOTE: only fire KVO notifications when items have actually changed
  [self willChangeValueForKey:WMF_SAFE_KEYPATH(self, items)];
  [_mutableItems setArray:items];
  [self didChangeValueForKey:WMF_SAFE_KEYPATH(self, items)];
}

- (NSArray *)items {
  return _mutableItems;
}

- (NSString *)analyticsContext {
  return @"Explore";
}

@end

NS_ASSUME_NONNULL_END
