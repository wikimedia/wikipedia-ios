#import <WMF/MWKSiteDataObject.h>
#import <WMF/MWKList.h>

@interface MWKSavedPageEntry : MWKSiteDataObject <MWKListObject>

@property (readonly, strong, nonatomic) NSDate *date;

- (instancetype)initWithURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithDict:(NSDictionary *)dict;

///
/// @name Legacy Data Migration Flags
///

/// Whether or not image data was migrated from `MWKDataStore` to `WMFImageController`.
@property (nonatomic, readonly) BOOL didMigrateImageData;

@end
