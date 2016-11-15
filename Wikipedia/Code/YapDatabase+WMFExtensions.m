#import "YapDatabase+WMFExtensions.h"
#import <YapDatabase/YapDatabaseCrossProcessNotification.h>

@implementation YapDatabase (WMFExtensions)

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static id sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self wmf_databaseWithDefaultConfiguration];
    });
    return sharedInstance;
}

+ (instancetype)wmf_databaseWithDefaultConfiguration {
    return [self wmf_databaseWithDefaultConfigurationAtPath:[[self class] wmf_databasePath]];
}

+ (void)wmf_registerViewsInDatabase:(YapDatabase *)db {
    YapDatabaseCrossProcessNotification *cp = [[YapDatabaseCrossProcessNotification alloc] initWithIdentifier:@"Wikipedia"];
    [db registerExtension:cp withName:@"WikipediaCrossProcess"];
    [MWKHistoryEntry registerViewsInDatabase:db];
    [WMFContentGroup registerViewsInDatabase:db];
}

+ (instancetype)wmf_databaseWithDefaultConfigurationAtPath:(NSString *)path {
    YapDatabaseOptions *options = [YapDatabaseOptions new];
    options.enableMultiProcessSupport = YES;
    options.aggressiveWALTruncationSize = 100 * 1024 * 1024; // 100 MB
    YapDatabase *db = [[YapDatabase alloc] initWithPath:path options:options];
    [YapDatabase wmf_registerViewsInDatabase:db];
    return db;
}

+ (NSString *)wmf_databasePath {
    NSString *databaseName = @"WikipediaYap.sqlite";

    NSURL *baseURL = [[NSFileManager defaultManager] wmf_containerURL];

    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];

    return databaseURL.filePathURL.path;
}

+ (NSString *)wmf_appSpecificDatabasePath {
    NSString *databaseName = @"WikipediaYap.sqlite";

    NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:YES
                                                               error:NULL];

    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];

    return databaseURL.filePathURL.path;
}

- (YapDatabaseConnection *)wmf_newReadConnection {
    YapDatabaseConnection *conn = [self newConnection];
    conn.objectCacheLimit = 100;
    conn.metadataCacheLimit = 0;
    return conn;
}

- (YapDatabaseConnection *)wmf_newLongLivedReadConnection {
    YapDatabaseConnection *conn = [self newConnection];
    conn.objectCacheLimit = 100;
    conn.metadataCacheLimit = 0;
    [conn beginLongLivedReadTransaction];
    return conn;
}

- (YapDatabaseConnection *)wmf_newWriteConnection {
    YapDatabaseConnection *conn = [self newConnection];
    conn.objectCacheLimit = 0;
    conn.metadataCacheLimit = 0;
    return conn;
}

- (void)wmf_registerView:(YapDatabaseView *)view withName:(NSString *)name {
    [self registerExtension:view withName:name];
}

@end
