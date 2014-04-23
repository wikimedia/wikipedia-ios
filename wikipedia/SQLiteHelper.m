//
//  SQLiteHelper.m
//  Wikipedia
//
//  Created by Brion on 4/23/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "SQLiteHelper.h"
#import <sqlite3.h>

#define SQLITE_THROW(x) {\
    int sqlite_errno = (x); \
    if (sqlite_errno != SQLITE_OK) { \
        @throw [NSException exceptionWithName:@"SQLiteHelperException" \
                                       reason:[NSString stringWithUTF8String:sqlite3_errmsg(_database)] \
                                     userInfo:@{@"sqlite_errno": [NSNumber numberWithInt:sqlite_errno]}]; \
    } \
}

@implementation SQLiteHelper
{
    sqlite3 *_database;
}

- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        SQLITE_THROW(sqlite3_open([path UTF8String], &_database));
    }
    return self;
}

- (void)dealloc {
    SQLITE_THROW(sqlite3_close(_database));
}

/**
 * Return an array of dictionaries for each matching row
 */
- (NSArray *)query:(NSString *)query params:(NSArray *)params
{
    sqlite3_stmt *statement;
    SQLITE_THROW(sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, nil));
    if (params) {
        [self bindParams:params statement:statement];
    }
    
    NSMutableArray *rows = [[NSMutableArray alloc] init];
    
    while (true) {
        int ret = sqlite3_step(statement);
        if (ret == SQLITE_ROW) {
            NSDictionary *row = [self extractRowFromStatement:statement];
            [rows addObject: row];
        } else if (ret == SQLITE_DONE) {
            // We're done!
            break;
        } else {
            SQLITE_THROW(ret);
        }
    }
    
    SQLITE_THROW(sqlite3_finalize(statement));
    
    return rows;
}

#pragma mark - Private methods

- (void)bindParams:(NSArray *)params statement:(sqlite3_stmt *)statement
{
    for (int i = 0; i < [params count]; i++) {
        int col = i + 1;
        NSObject *param = params[i];
        if ([param isKindOfClass:[NSString class]]) {
            NSString *str = (NSString *)param;
            SQLITE_THROW(sqlite3_bind_text(statement, col, [str UTF8String], -1, nil));
        } else {
            @throw [NSException exceptionWithName:@"SQLiteHelperException"
                                           reason:@"Unimplemented type in SQLHelper bindParams:statement:"
                                         userInfo:@{}];
        }
    }
}

- (NSDictionary *)extractRowFromStatement:(sqlite3_stmt *)statement
{
    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
    
    int columnCount = sqlite3_column_count(statement);
    for (int i = 0; i < columnCount; i++) {
        int col = i;
        NSString *name = [NSString stringWithUTF8String:sqlite3_column_name(statement, col)];
        NSObject *value;
        switch (sqlite3_column_type(statement, col)) {
            case SQLITE_INTEGER:
                value = [NSNumber numberWithInt:sqlite3_column_int(statement, col)];
                break;
            case SQLITE_FLOAT:
                value = [NSNumber numberWithDouble:sqlite3_column_double(statement, col)];
                break;
            case SQLITE_TEXT:
            {
                const char *bytes = (const char *)sqlite3_column_text(statement, col);
                int nbytes = sqlite3_column_bytes(statement, col);
                if (nbytes > 0) {
                    value = [NSString stringWithUTF8String:bytes];
                } else {
                    value = @"";
                }
                break;
            }
            case SQLITE_BLOB:
            {
                const char *bytes = sqlite3_column_blob(statement, col);
                int nbytes = sqlite3_column_bytes(statement, col);
                if (nbytes > 0) {
                    value = [NSData dataWithBytes:bytes length:nbytes];
                } else {
                    value = [[NSData alloc] init];
                }
                break;
            }
            case SQLITE_NULL:
                value = [NSNull null];
                break;
            default:
                @throw [NSException exceptionWithName:@"SQLiteHelperException"
                                               reason:@"Unimplmemented column type in SQLHelper extractRowFromStatement:"
                                             userInfo:@{}];
        }
        row[name] = value;
    }
    
    return [NSDictionary dictionaryWithDictionary:row];
}

@end
