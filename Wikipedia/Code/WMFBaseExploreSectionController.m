//
//  WMFBaseExploreSectionController.m
//  Wikipedia
//
//  Created by Corey Floyd on 1/25/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "WMFBaseExploreSectionController.h"
#import <PromiseKit/SCNetworkReachability+AnyPromise.h>
#import "WMFEmptySectionTableViewCell.h"
#import "UIView+WMFDefaultNib.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "MWKDataStore.h"
#import "MWKUserDataStore.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFExploreSectionControllerException = @"WMFExploreSectionControllerException";

@interface WMFBaseExploreSectionController ()

@property (nonatomic, strong, readwrite) MWKDataStore* dataStore;

/**
 *  The items visible to the WMFExploreViewController
 *  May contain placeholder items
 */
@property (nonatomic, strong) NSMutableArray* mutableItems;

@property (nonatomic, strong, nullable) NSArray* fetchedItems;

@property (nonatomic, strong, nullable) AnyPromise* fetcherPromise;

@property (nonatomic, strong, readwrite, nullable) NSError* fetchError;

@end

@implementation WMFBaseExploreSectionController

#pragma mark - Init

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    NSParameterAssert(dataStore);
    self = [super init];
    if (self) {
        self.dataStore    = dataStore;
        self.mutableItems = [NSMutableArray array];
        [self setItemsToPlaceholders];
    }
    return self;
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore items:(NSArray*)items {
    NSParameterAssert(items);
    self = [self initWithDataStore:dataStore];
    if (self) {
        [self.mutableItems addObjectsFromArray:items];
    }
    return self;
}

- (NSString*)description {
    NSAssert([self conformsToProtocol:@protocol(WMFExploreSectionController)],
             @"Expected subclass of %@ to conform to %@, but %@ does not.",
             [WMFBaseExploreSectionController class],
             NSStringFromProtocol(@protocol(WMFExploreSectionController)),
             [self class]);
    return [NSString stringWithFormat:@"%@ identifier = %@",
            [super description], [(id < WMFExploreSectionController >)self sectionIdentifier]];
}

#pragma mark - WMFBaseExploreSectionController

- (BOOL)containsPlaceholders {
    return [self.items bk_all:^BOOL (id obj) {
        return [obj isKindOfClass:[NSNumber class]];
    }];
}

- (MWKSavedPageList*)savedPageList {
    return self.dataStore.userDataStore.savedPageList;
}

- (MWKHistoryList*)historyList {
    return self.dataStore.userDataStore.historyList;
}

- (NSUInteger)numberOfPlaceholderCells {
    return 3;
}

- (NSString*)cellIdentifier {
    @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                   reason:@"Method must be implemented by subclass"
                                 userInfo:nil];
}

- (UINib*)cellNib {
    @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                   reason:@"Method must be implemented by subclass"
                                 userInfo:nil];
}

- (nullable NSString*)placeholderCellIdentifier {
    return nil;
}

- (nullable UINib*)placeholderCellNib {
    return nil;
}

- (void)configureEmptyCell:(WMFEmptySectionTableViewCell*)cell {
    cell.emptyTextLabel.text = MWLocalizedString(@"home-empty-section", nil);
    [cell.reloadButton setTitle:MWLocalizedString(@"home-empty-section-check-again", nil) forState:UIControlStateNormal];
}

- (void)configureCell:(UITableViewCell*)cell withItem:(id)item atIndexPath:(nonnull NSIndexPath*)indexPath {
    @throw [NSException exceptionWithName:WMFExploreSectionControllerException
                                   reason:@"Method must be implemented by subclass"
                                 userInfo:nil];
}

- (AnyPromise*)fetchData {
    return [AnyPromise promiseWithValue:self.items];
}

#pragma mark - WMFExploreSectionController

- (void)registerCellsInTableView:(UITableView*)tableView {
    [tableView registerNib:[self cellNib] forCellReuseIdentifier:[self cellIdentifier]];
    if ([self placeholderCellIdentifier] && [self placeholderCellNib]) {
        [tableView registerNib:[self placeholderCellNib] forCellReuseIdentifier:[self placeholderCellIdentifier]];
    }
    [tableView registerNib:[WMFEmptySectionTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFEmptySectionTableViewCell identifier]];
}

- (NSString*)cellIdentifierForItemIndexPath:(NSIndexPath*)indexPath {
    if ([self shouldShowPlaceholderCell]) {
        return [self placeholderCellIdentifier];
    }
    if ([self shouldShowEmptyCell]) {
        return [WMFEmptySectionTableViewCell identifier];
    }
    return [self cellIdentifier];
}

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    if ([self shouldShowPlaceholderCell]) {
        return;
    } else if ([self shouldShowEmptyCell]) {
        WMFEmptySectionTableViewCell* emptyCell = (id)cell;
        if (![emptyCell.reloadButton bk_hasEventHandlersForControlEvents:UIControlEventTouchUpInside]) {
            @weakify(self);
            [emptyCell.reloadButton bk_addEventHandler:^(id sender) {
                @strongify(self);
                [self resetData];
                [self fetchDataIfError];
            } forControlEvents:UIControlEventTouchUpInside];
        }
        [self configureEmptyCell:emptyCell];
    } else {
        [self configureCell:cell withItem:self.items[indexPath.row] atIndexPath:indexPath];
    }
}

- (BOOL)shouldSelectItemAtIndexPath:(NSIndexPath*)indexPath {
    if ([self shouldShowPlaceholderCell]) {
        return NO;
    }
    if ([self shouldShowEmptyCell]) {
        return NO;
    }
    return YES;
}

- (AnyPromise*)fetchDataIfNeeded {
    return [self fetchDataIgnoreError:NO ignoreCurrentItems:NO];
}

- (AnyPromise*)fetchDataIfError {
    return [self fetchDataIgnoreError:YES ignoreCurrentItems:NO];
}

- (AnyPromise*)fetchDataUserInitiated {
    return [self fetchDataIgnoreError:YES ignoreCurrentItems:YES];
}

- (AnyPromise*)fetchDataIgnoreError:(BOOL)ignoreError ignoreCurrentItems:(BOOL)ignoreCurrentItems {
    if (!ignoreError && [self lastFetchFailed]) {
        return [AnyPromise promiseWithValue:self.fetchError];
    } else if (!ignoreCurrentItems && [self hasResults]) {
        return [AnyPromise promiseWithValue:self.items];
    } else if ([self isFetching]) {
        return [AnyPromise promiseWithValue:self.items];
    } else {
        [self setItemsToPlaceholders];
        @weakify(self);
        self.fetcherPromise = [self fetchData].then(^(NSArray* items){
            @strongify(self);
            self.fetcherPromise = nil;
            self.fetchError = nil;
            self.fetchedItems = items;
            [self setItemsToFetchedItems:items];
            return self.items;
        }).catch(^(NSError* error){
            @strongify(self);
            DDLogError(@"Failed to fetch items for section %@. %@", self, error);
            self.fetcherPromise = nil;
            self.fetchError = error;
            self.fetchedItems = nil;
            [self setItemsToError:error];
            @weakify(self);
            //Clear network error on network reconnect
            if ([error wmf_isNetworkConnectionError]) {
                SCNetworkReachability().then(^{
                    @strongify(self);
                    self.fetchError = nil;
                });
            }
            return error;
        });
        return self.fetcherPromise;
    }
}

- (void)resetData {
    self.fetchError = nil;
    [self setItemsToPlaceholders];
}

#pragma mark - Utility

- (void)setItemsToPlaceholders {
    if (![self shouldShowPlaceholderCell]) {
        return;
    }
    NSMutableArray* placeholders = [NSMutableArray array];
    for (int i = 0; i < [self numberOfPlaceholderCells]; i++) {
        [placeholders addObject:@(i)];
    }
    [self.mutableItems removeObjectsInArray:self.mutableItems];
    [self.mutableItems addObjectsFromArray:placeholders];
}

- (void)setItemsToError:(NSError*)error {
    [self.mutableItems removeObjectsInArray:self.mutableItems];
    [self.mutableItems addObject:error];
}

- (void)setItemsToFetchedItems:(NSArray*)items {
    if ([self.mutableItems count] == 0) {
        [self.mutableItems insertObjects:items atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])]];
    } else if ([self.mutableItems count] == [items count]) {
        [self.mutableItems replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])] withObjects:items];
    } else {
        [self.mutableItems removeObjectsInArray:self.mutableItems];
        [self.mutableItems insertObjects:items atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])]];
    }
}

- (BOOL)shouldShowPlaceholderCell {
    if ([self numberOfPlaceholderCells] > 0
        && [self.fetchedItems count] == 0
        && self.fetchError == nil
        && [self placeholderCellIdentifier] && [self placeholderCellNib]) {
        return YES;
    }
    return NO;
}

- (BOOL)shouldShowEmptyCell {
    if ([self.fetchedItems count] == 0
        && self.fetchError) {
        return YES;
    }
    return NO;
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

#pragma mark - Items KVO

- (NSArray*)items {
    return _mutableItems;
}

- (NSMutableArray*)mutableItems {
    return [self mutableArrayValueForKey:WMF_SAFE_KEYPATH(self, items)];
}

- (NSUInteger)countOfItems {
    return [_mutableItems count];
}

- (id)objectInItemsAtIndex:(NSUInteger)index {
    return [_mutableItems objectAtIndex:index];
}

- (void)insertObject:(id)object inItemsAtIndex:(NSUInteger)index {
    [_mutableItems insertObject:object atIndex:index];
}

- (void)insertItems:(NSArray*)array atIndexes:(NSIndexSet*)indexes {
    [_mutableItems insertObjects:array atIndexes:indexes];
}

- (void)removeObjectFromItemsAtIndex:(NSUInteger)index {
    [_mutableItems removeObjectAtIndex:index];
}

- (void)removeItemsAtIndexes:(NSIndexSet*)indexes {
    [_mutableItems removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInItemsAtIndex:(NSUInteger)index withObject:(id)object {
    [_mutableItems replaceObjectAtIndex:index withObject:object];
}

- (void)replaceItemsAtIndexes:(NSIndexSet*)indexes withItems:(NSArray*)array {
    [_mutableItems replaceObjectsAtIndexes:indexes withObjects:array];
}

- (NSString*)analyticsContext {
    return @"Explore";
}

@end

NS_ASSUME_NONNULL_END
