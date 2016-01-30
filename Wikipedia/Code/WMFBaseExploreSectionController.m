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

NS_ASSUME_NONNULL_BEGIN

static NSString* const WMFExploreSectionControllerException = @"WMFExploreSectionControllerException";

@interface WMFBaseExploreSectionController ()
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

- (instancetype)initWithItems:(NSArray*)items {
    self = [self init];
    if (self) {
        [self.mutableItems addObjectsFromArray:items];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.mutableItems = [NSMutableArray array];
        if ([self numberOfPlaceholderCells] > 0) {
            [self setItemsToPlaceholders];
        }
    }
    return self;
}

#pragma mark - WMFBaseExploreSectionController

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

- (BOOL)showsEmptyCell {
    return NO;
}

- (void)configureEmptyCell:(WMFEmptySectionTableViewCell*)cell {
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
    if ([self shouldShowEmptyCell]) {
        [tableView registerNib:[WMFEmptySectionTableViewCell wmf_classNib] forCellReuseIdentifier:[WMFEmptySectionTableViewCell identifier]];
    }
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
                [self fetchData];
            } forControlEvents:UIControlEventTouchUpInside];
        }
        [self configureEmptyCell:emptyCell];
    } else {
        [self configureCell:cell withItem:self.items[indexPath.row] atIndexPath:indexPath];
    }
}

- (MWKHistoryDiscoveryMethod)discoveryMethod {
    return MWKHistoryDiscoveryMethodUnknown;
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
        @weakify(self);
        self.fetcherPromise = [self fetchData].then(^(NSArray* items){
            @strongify(self);
            self.fetcherPromise = nil;
            self.fetchError = nil;
            self.fetchedItems = items;
            if ([self.mutableItems count] == 0) {
                [self.mutableItems insertObjects:items atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])]];
            } else if ([self.mutableItems count] == [items count]) {
                [self.mutableItems replaceObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])] withObjects:items];
            } else {
                [self.mutableItems removeObjectsInArray:self.mutableItems];
                [self.mutableItems insertObjects:items atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [items count])]];
            }
            return self.items;
        }).catch(^(NSError* error){
            @strongify(self);
            self.fetcherPromise = nil;
            self.fetchError = error;
            self.fetchedItems = nil;
            [self.mutableItems removeObjectsInArray:self.mutableItems];
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
    NSMutableArray* placeholders = [NSMutableArray array];
    for (int i = 0; i < [self numberOfPlaceholderCells]; i++) {
        [placeholders addObject:@(i)];
    }
    [self.mutableItems removeObjectsInArray:self.mutableItems];
    [self.mutableItems addObjectsFromArray:placeholders];
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
        && self.fetchError
        && [self shouldShowEmptyCell]) {
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

@end

NS_ASSUME_NONNULL_END
