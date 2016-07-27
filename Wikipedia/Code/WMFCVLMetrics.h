#import <Foundation/Foundation.h>

@interface WMFCVLMetrics : NSObject <NSCopying>
@property (nonatomic) CGFloat interColumnSpacing;
@property (nonatomic) CGFloat interSectionSpacing;
@property (nonatomic) CGFloat interItemSpacing;
@property (nonatomic) UIEdgeInsets contentInsets;
@property (nonatomic) UIEdgeInsets sectionInsets;
@property (nonatomic) NSInteger numberOfColumns;
@property (nonatomic, copy) NSArray *columnWeights;
@end
