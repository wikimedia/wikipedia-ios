#import <Foundation/Foundation.h>

@protocol WMFDatabaseStorable <NSObject>

+ (NSString *)databaseCollectionName;

+ (NSString *)databaseKeyForURL:(NSURL *)url;

- (NSString *)databaseKey;

@end
