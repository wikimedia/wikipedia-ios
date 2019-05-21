@import Foundation;

@interface WMFHTMLElement : NSObject

@property (nonatomic, nonnull) NSString *tagName;
@property (nonatomic) NSInteger startLocation;
@property (nonatomic) NSInteger endLocation;
@property (nonatomic, nullable) NSMutableArray<WMFHTMLElement *> *children;
@property (nonatomic) NSUInteger nestingDepth;
@property (nonatomic) BOOL hasNestedElements;

- (nonnull instancetype)initWithTagName:(nonnull NSString *)tagName;

@end
