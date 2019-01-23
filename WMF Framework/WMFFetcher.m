#import "WMFFetcher.h"
#import <WMF/WMF-Swift.h>

@interface WMFFetcher ()

@property (nonatomic, strong, readwrite) WMFSession *session;
@property (nonatomic, strong, readwrite) WMFConfiguration *configuration;

@end

@implementation WMFFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.session = [WMFSession shared];
        self.configuration = [WMFConfiguration current];
    }
    return self;
}

@end
