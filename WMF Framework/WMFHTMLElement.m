#import "WMFHTMLElement.h"

@implementation WMFHTMLElement

- (instancetype)initWithTagName:(NSString *)tagName {
    self = [super self];
    if (self) {
        self.tagName = tagName;
        self.startLocation = NSNotFound;
        self.endLocation = NSNotFound;
        self.nestingDepth = 0;
    }
    return self;
}

@end
