
#import <Foundation/Foundation.h>

@protocol WMFDatabaseStorable <NSObject>

+ (NSString*)databaseCollectionName;

- (NSString*)databaseKey;

@end
