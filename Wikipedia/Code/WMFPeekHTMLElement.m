#import "WMFPeekHTMLElement.h"

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
            self.url = [self originalSrcURLFromProxyURL:[NSURL URLWithString:src]];
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

- (NSURL*)originalSrcURLFromProxyURL:(NSURL*)url {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
    if (!urlComponents || !urlComponents.queryItems) {
        return nil;
    }
    NSArray* queryItems = urlComponents.queryItems;
    NSURLQueryItem* originalSrcItem = [queryItems bk_match:^BOOL (NSURLQueryItem* item) {
        return [item.name isEqualToString:@"originalSrc"];
    }];
    return [NSURL URLWithString:originalSrcItem.value];
}

@end
