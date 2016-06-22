#import "WMFPeekHTMLElement.h"

@interface WMFPeekHTMLElement()

@property (nonatomic, strong, readwrite) NSString* tagName;
@property (nonatomic, strong, readwrite, nullable) NSString* src;
@property (nonatomic, strong, readwrite, nullable) NSString* href;

@end

@implementation WMFPeekHTMLElement

- (instancetype)initWithTagName:(NSString*)tagName src:(NSString*)src href:(NSString*)href {
    self = [super init];
    if (self) {
        self.tagName = tagName;
        self.src = src;
        self.href = href;
    }
    return self;
}

@end
