#import "WMFPeekHTMLElement.h"
#import "NSURL+WMFProxyServer.h"

@interface WMFPeekHTMLElement ()

@property(nonatomic, readwrite) WMFPeekElementType type;
@property(nonatomic, strong, readwrite, nullable) NSURL *url;

@end

@implementation WMFPeekHTMLElement

- (instancetype)initWithTagName:(NSString *)tagName src:(NSString *)src href:(NSString *)href {
  NSParameterAssert(tagName);
  if (!tagName) {
    return nil;
  }
  self = [super init];
  if (self) {
    if ([tagName isEqualToString:@"IMG"]) {
      self.type = WMFPeekElementTypeImage;
      if (src) {
        self.url = [[NSURL URLWithString:src] wmf_imageProxyOriginalSrcURL];
      }
    } else if ([tagName isEqualToString:@"A"]) {
      self.type = WMFPeekElementTypeAnchor;
      if (href) {
        self.url = [NSURL URLWithString:href];
      }
    } else {
      self.type = WMFPeekElementTypeUnpeekable;
      self.url = nil;
    }
  }
  return self;
}

@end
