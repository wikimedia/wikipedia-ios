#import <Foundation/Foundation.h>

@interface WMFHTMLElement : NSObject

@property (nonatomic, nonnull) NSString *tagName;
@property (nonatomic) NSInteger startLocation;
@property (nonatomic) NSInteger endLocation;
@property (nonatomic, nullable) NSMutableArray<WMFHTMLElement *> *children;
@property (nonatomic) NSUInteger nestingDepth;

- (nonnull instancetype)initWithTagName:(nonnull NSString *)tagName;

@end
