
#import <Foundation/Foundation.h>

@interface WMFDatabaseHouseKeeper : NSObject

- (BOOL)performHouseKeepingOnManagedObjectContext:(NSManagedObjectContext *)moc error:(NSError **)outError;

@end
