//
//  DataMigrator.h
//  Wikipedia
//
//  Created by Brion on 4/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataMigrator : NSObject

- (id)init;

/**
 * Is there anything that needs to be migrated?
 */
- (BOOL)hasData;

/**
 * Return the extracted JSON blobs from the savedPagesDB database table.
 * Each contains 'lang', 'title', and 'key' strings.
 *
 * @return (NSArray *) of (NSDictionary *)s.
 */
- (NSArray *)extractSavedPages;

/**
 * Delete the old files.
 * @todo implement this
 */
- (void)removeOldData;

@end
