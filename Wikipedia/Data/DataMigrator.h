//
//  DataMigrator.h
//  Wikipedia
//
//  Created by Brion on 4/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataMigrator : NSObject

/// @return `YES` if a SQLLite file exists at the master database path, otherwise `NO`.
+ (BOOL)hasData;

/// Remove the master database file.
+ (void)removeOldData;

- (id)init;

/**
 * Return the extracted JSON blobs from the savedPagesDB database table.
 * Each contains 'lang', 'title', and 'key' strings.
 *
 * @return (NSArray *) of (NSDictionary *)s.
 */
- (NSArray*)extractSavedPages;

@end
