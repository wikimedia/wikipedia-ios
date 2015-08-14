//
//  SSCoreDataSource.h
//  SSDataSources
//
//  Created by Jonathan Hersh on 6/7/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSBaseDataSource.h"
#import <CoreData/CoreData.h>

/**
 * Generic table/collectionview data source, useful when your data comes from an NSFetchedResultsController.
 * Automatically inserts/reloads/deletes rows in the table or collection view in response to FRC events.
 */

@interface SSCoreDataSource : SSBaseDataSource <NSFetchedResultsControllerDelegate>

/**
 *  Create a data source with a fetch request, context, and keypath.
 *
 *  @param request            fetch request specifying your objects
 *  @param context            managed object context to use
 *  @param sectionNameKeyPath nil or section keypath
 *
 *  @return an initialized data source
 */
- (instancetype) initWithFetchRequest:(NSFetchRequest *)request
                            inContext:(NSManagedObjectContext *)context
                   sectionNameKeyPath:(NSString *)sectionNameKeyPath;

/**
 *  Create a data source with an FRC that you've already set up.
 *
 *  @param controller your FRC
 *
 *  @return an initialized data source
 */
- (instancetype) initWithFetchedResultsController:(NSFetchedResultsController *)controller;

/**
 *  Find a managed object by its ID and return its index path.
 *
 *  @param objectId managed object ID
 *
 *  @return an index path, or nil if the object is not found
 */
- (NSIndexPath *) indexPathForItemWithId:(NSManagedObjectID *)objectId;

/**
 * The data source's fetched results controller. You probably don't need to set this directly
 * as both initializers will do this for you.
 */
@property (nonatomic, strong) NSFetchedResultsController *controller;

/**
 * Any error experienced during the most recent fetch.
 * nil if the fetch succeeded.
 */
@property (nonatomic, strong, readonly) NSError *fetchError;

// Block called when move is needed on a CoreData object.
typedef void (^SSCoreDataMoveRowBlock) (id object,                          // The object being moved
                                        NSIndexPath *sourceIndexPath,       // The source index path
                                        NSIndexPath *destinationIndexPath); // The destination index path

/**
 * CoreData move row block, called after a user has moved a cell and the
 * associated data should be updated.
 */
@property (nonatomic, copy) SSCoreDataMoveRowBlock coreDataMoveRowBlock;

@end
