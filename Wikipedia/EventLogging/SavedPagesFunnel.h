//
//  SavedPagesFunnel.h
//  Wikipedia
//
//  Created by Brion on 7/17/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "EventLoggingFunnel.h"

@interface SavedPagesFunnel : EventLoggingFunnel

@property NSString* appInstallId;

- (id)init;

/**
 * Log the saving of a new page to the saved set.
 */
- (void)logSaveNew;

/**
 * What does this represent? Update of a single page, or of the entire data set?
 */
- (void)logUpdate;

/**
 * What does this represent? Import of a single page, or of the entire data set?
 */
- (void)logImportOnSubdomain:(NSString*)subdomain;

/**
 * Log the removal of a saved page from the saved list
 */
- (void)logDelete;

/**
 * @fixme What does this represent
 */
- (void)logEditAttempt;

/**
 * @fixme What does this represent
 */
- (void)logEditRefresh;

/**
 * @fixme What does this represent
 */
- (void)logEditAfterRefresh;

@end
