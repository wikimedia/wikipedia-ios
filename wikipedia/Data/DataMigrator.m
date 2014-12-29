//
//  DataMigrator.m
//  Wikipedia
//
//  Created by Brion on 4/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. Some rights reserved.
//

#import "DataMigrator.h"
#import "SQLiteHelper.h"

@implementation DataMigrator
{
    SQLiteHelper *masterDB;
    SQLiteHelper *savedPagesDB;
}

#pragma mark - Public methods

- (id)init
{
    self = [super init];
    if (self) {
        NSString *dbPath = [self localLibraryPath:@"Caches/Databases.db"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
            NSLog(@"Opening sqlite database from %@", dbPath);
            masterDB = [[SQLiteHelper alloc] initWithPath:dbPath];
        }
    }
    return self;
}

- (BOOL)hasData
{
    return (masterDB != NULL);
}

- (NSArray *)extractSavedPages
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for (NSDictionary *row in [self fetchRawSavedPages]) {
        NSString *jsonString = row[@"value"];
        NSData *jsonBlob = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonBlob options:0 error:nil];
        [arr addObject:dict];
    }
    return [NSArray arrayWithArray:arr];
}

- (void)removeOldData
{
    if ([self hasData]) {
        NSLog(@"Deleting old app's Caches/Databases.db");
        masterDB = nil;
        NSString *dbPath = [self localLibraryPath:@"Caches/Databases.db"];
        [[NSFileManager defaultManager] removeItemAtPath:dbPath error:nil];
    }
}

#pragma mark - Private methods

/**
 * Return absolute path for relative path to the installed app's documents folder.
 */
- (NSString *)localDocumentPath:(NSString *)local
{
    return [[self documentRootPath] stringByAppendingPathComponent:local];
}

- (NSString *)documentRootPath
{
    NSArray* documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentRootPath = [documentPaths objectAtIndex:0];
    return documentRootPath;
}

/**
 * Return absolute path for relative path to the installed app's Library folder.
 */
- (NSString *)localLibraryPath:(NSString *)local
{
    return [[self libraryRootPath] stringByAppendingPathComponent:local];
}

- (NSString *)libraryRootPath
{
    NSArray* libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* libraryRootPath = [libraryPaths objectAtIndex:0];
    return libraryRootPath;
}

- (NSArray *)fetchRawSavedPages
{
    savedPagesDB = [self openDatabaseWithName:@"savedPagesDB"];
    return [savedPagesDB query:@"SELECT value FROM savedPagesDB" params:nil];
}

- (SQLiteHelper *)openDatabaseWithName:(NSString *)dbname
{
    NSArray *rows = [masterDB query:@"SELECT origin, path FROM Databases WHERE name=?" params:@[dbname]];
    NSDictionary *row = rows[0];
    NSLog(@"row: %@", row);
    NSString *path = [[[self localLibraryPath:@"Caches"] stringByAppendingPathComponent:row[@"origin"]] stringByAppendingPathComponent:row[@"path"]];
    NSLog(@"opening path %@", path);
    return [[SQLiteHelper alloc] initWithPath:path];
}

@end
