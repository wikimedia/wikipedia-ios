#import "WMFPeekHTMLElement.h"
#import "NSURL+WMFExtras.h"

@interface WMFPeekHTMLElement()

@property (nonatomic, readwrite) WMFPeekElementType type;
@property (nonatomic, strong, readwrite, nullable) NSURL* url;

@end

@implementation WMFPeekHTMLElement

- (instancetype)initWithTagName:(NSString*)tagName src:(NSString*)src href:(NSString*)href {
    self = [super init];
    if (self) {
        if ([tagName isEqualToString:@"IMG"]) {
            self.type = WMFPeekElementTypeImage;
            self.url = [[NSURL URLWithString:src] wmf_imageProxyOriginalSrcURL];
        }else if([tagName isEqualToString:@"A"]) {
            self.type = WMFPeekElementTypeAnchor;
            self.url = [NSURL URLWithString:href];
        }else{
            self.type = WMFPeekElementTypeUnpeekable;
            self.url = nil;
        }
    }
    return self;
}

@end
