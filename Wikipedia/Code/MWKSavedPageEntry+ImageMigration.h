#import "MWKSavedPageEntry.h"

@interface MWKSavedPageEntry ()

/// Mutable redeclaration of migration flag. Set using @c MWKSavedPageList
/// @see -[MWKSavedPageList markImageDataAsMigratedForEntryWithTitle:]
@property(nonatomic, readwrite) BOOL didMigrateImageData;

@end
