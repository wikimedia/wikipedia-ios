#import "WMFBaseRequestSerializer.h"
#import "AFHTTPRequestSerializer+WMFRequestHeaders.h"

@implementation WMFBaseRequestSerializer

- (instancetype)init {
  self = [super init];
  if (self) {
    [self wmf_applyAppRequestHeaders];
  }
  return self;
}

@end
