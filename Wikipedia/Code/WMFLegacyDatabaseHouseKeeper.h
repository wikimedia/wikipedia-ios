#import <Foundation/Foundation.h>

@interface WMFLegacyDatabaseHouseKeeper : NSObject

- (BOOL)performHouseKeepingOnManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)outError;

@end
