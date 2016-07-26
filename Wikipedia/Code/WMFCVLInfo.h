#import <Foundation/Foundation.h>

@class WMFCVLColumn;
@class WMFCVLSection;
@class WMFCVLAttributes;

@interface WMFCVLInfo : NSObject

@property (nonatomic, strong, nonnull, readonly) NSArray <WMFCVLColumn *> *columns;
@property (nonatomic, strong, nonnull, readonly) NSArray <WMFCVLSection *> *sections;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

- (nonnull instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns numberOfSections:(NSInteger)numberOfSections NS_DESIGNATED_INITIALIZER;
- (void)enumerateSectionsWithBlock:(nonnull void(^)(WMFCVLSection * _Nonnull section, NSUInteger idx, BOOL * _Nonnull stop))block;
- (void)enumerateColumnsWithBlock:(nonnull void(^)(WMFCVLColumn * _Nonnull column, NSUInteger idx, BOOL * _Nonnull stop))block;


- (nullable WMFCVLAttributes *)layoutAttributesForItemAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable WMFCVLAttributes *)layoutAttributesForSupplementaryViewOfKind:(nonnull NSString *)elementKind atIndexPath:(nonnull NSIndexPath *)indexPath;

@end