//
//  SSCoreDataSource.m
//  SSDataSources
//
//  Created by Jonathan Hersh on 6/7/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSDataSources.h"

@interface SSCoreDataSource ()

// For UICollectionView
@property (nonatomic, strong) NSMutableArray *sectionUpdates;
@property (nonatomic, strong) NSMutableArray *objectUpdates;

- (void) _performFetch;

@end

@implementation SSCoreDataSource

- (instancetype)init {
    if ((self = [super init])) {
        _sectionUpdates = [NSMutableArray new];
        _objectUpdates = [NSMutableArray new];
    }
    
    return self;
}

- (instancetype) initWithFetchedResultsController:(NSFetchedResultsController *)aController {
    if ((self = [self init])) {
        _controller = aController;
        self.controller.delegate = self;
        
        if (!self.controller.fetchedObjects) {
            [self _performFetch];
        }
    }
    
    return self;
}

- (instancetype)initWithFetchRequest:(NSFetchRequest *)request
                           inContext:(NSManagedObjectContext *)context
                  sectionNameKeyPath:(NSString *)sectionNameKeyPath {
    
    return [self initWithFetchedResultsController:
            [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                managedObjectContext:context
                                                  sectionNameKeyPath:sectionNameKeyPath
                                                           cacheName:nil]];
}

- (void)dealloc {
    self.controller.delegate = nil;
    self.controller = nil;
    self.coreDataMoveRowBlock = nil;
    [self.sectionUpdates removeAllObjects];
    [self.objectUpdates removeAllObjects];
}

#pragma mark - Fetching

- (void)_performFetch {
    NSError *fetchErr;
    [self.controller performFetch:&fetchErr];
    _fetchError = fetchErr;
}

#pragma mark - SSBaseDataSource

- (NSUInteger)numberOfSections {
    return (NSUInteger)[[self.controller sections] count];
}

- (NSUInteger)numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.controller sections][(NSUInteger)section];
    return (NSUInteger)[sectionInfo numberOfObjects];
}

- (id)itemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.controller objectAtIndexPath:indexPath];
}

#pragma mark - Core Data access

- (NSIndexPath *)indexPathForItemWithId:(NSManagedObjectID *)objectId {
    for (NSUInteger section = 0; section < [self numberOfSections]; section++) {
        id <NSFetchedResultsSectionInfo> sec = [self.controller sections][section];
        
        NSUInteger index = [[sec objects] indexOfObjectPassingTest:^BOOL(NSManagedObject *object,
                                                                         NSUInteger idx,
                                                                         BOOL *stop) {
            return [[object objectID] isEqual:objectId];
        }];
    
        if (index != NSNotFound) {
            return [NSIndexPath indexPathForRow:(NSInteger)index inSection:(NSInteger)section];
        }
    }
  
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title
               atIndex:(NSInteger)index {
    return [self.controller sectionForSectionIndexTitle:title atIndex:index];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.controller sectionIndexTitles];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.controller sections][(NSUInteger)section];
    return [sectionInfo name];
}

- (void)tableView:(UITableView *)tableView
moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
      toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    id item = [self itemAtIndexPath:sourceIndexPath];
    
    if (self.coreDataMoveRowBlock) {
        self.coreDataMoveRowBlock(item, sourceIndexPath, destinationIndexPath);
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName {
    return sectionName;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    UITableView *tableView = self.tableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            change[@(type)] = newIndexPath;
            [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                             withRowAnimation:self.rowAnimation];
            break;
            
        case NSFetchedResultsChangeDelete:
            change[@(type)] = indexPath;
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:self.rowAnimation];
            break;
            
        case NSFetchedResultsChangeUpdate:
            change[@(type)] = indexPath;
            [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:self.rowAnimation];
            break;
            
        case NSFetchedResultsChangeMove:
            change[@(type)] = @[ indexPath, newIndexPath ];
            [tableView deleteRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:self.rowAnimation];
            [tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                             withRowAnimation:self.rowAnimation];
            break;
    }
    
    [self.objectUpdates addObject:change];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    UITableView *tableView = self.tableView;
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:self.rowAnimation];
            change[@(type)] = @[@(sectionIndex)];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:self.rowAnimation];
            change[@(type)] = @[@(sectionIndex)];
            break;
        default:
            return;
    }
    
    [self.sectionUpdates addObject:change];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    
    UICollectionView *collectionView = self.collectionView;
    
    if (collectionView) {
        
        if ([self.sectionUpdates count] > 0) {
            [collectionView performBatchUpdates:^{
                for (NSDictionary *change in self.sectionUpdates) {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id secnum, BOOL *stop) {
                        NSFetchedResultsChangeType type = (NSFetchedResultsChangeType)[key unsignedIntegerValue];
                        NSIndexSet *section = [NSIndexSet indexSetWithIndex:[secnum unsignedIntegerValue]];
                        
                        switch( type ) {
                            case NSFetchedResultsChangeInsert:
                                [collectionView insertSections:section];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [collectionView deleteSections:section];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [collectionView reloadSections:section];
                                break;
                            default:
                                break;
                        }
                    }];
                }
            } completion:^(BOOL finished) {
                [self.sectionUpdates removeAllObjects];
                [self.objectUpdates removeAllObjects];
                
                // Hackish; force recalculation of empty view state
                self.emptyView = self.emptyView;
            }];
        } else if ([self.objectUpdates count] > 0) {
            [collectionView performBatchUpdates:^{
                for (NSDictionary *change in self.objectUpdates) {
                    [change enumerateKeysAndObjectsUsingBlock:^(NSNumber *key, id indexPath, BOOL *stop) {
                        NSFetchedResultsChangeType type = [key unsignedIntegerValue];
                        
                        switch( type ) {
                            case NSFetchedResultsChangeInsert:
                                [collectionView insertItemsAtIndexPaths:@[ indexPath ]];
                                break;
                            case NSFetchedResultsChangeDelete:
                                [collectionView deleteItemsAtIndexPaths:@[ indexPath ]];
                                break;
                            case NSFetchedResultsChangeUpdate:
                                [collectionView reloadItemsAtIndexPaths:@[ indexPath ]];
                                break;
                            case NSFetchedResultsChangeMove:
                                [collectionView moveItemAtIndexPath:indexPath[0]
                                                        toIndexPath:indexPath[1]];
                                break;
                        }
                    }];
                }
            } completion:^(BOOL finished) {
                [self.objectUpdates removeAllObjects];
                
                // Hackish; force recalculation of empty view state
                self.emptyView = self.emptyView;
            }];
        }
    }
}

@end
