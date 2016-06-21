#import "WMFPeekHTMLElement.h"

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
