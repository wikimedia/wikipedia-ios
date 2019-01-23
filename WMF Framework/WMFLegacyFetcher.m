#import "WMFLegacyFetcher.h"
#import <WMF/WMF-Swift.h>

@interface WMFLegacyFetcher ()

@property (nonatomic, strong, readwrite) WMFFetcher *fetcher;

@end

@implementation WMFLegacyFetcher

- (instancetype)init {
    self = [super init];
    if (self) {
        self.fetcher = [[WMFFetcher alloc] initWithSession:[WMFSession shared] configuration:[WMFConfiguration current]];
    }
    return self;
}

- (WMFSession *)session {
    return self.fetcher.session;
}

- (WMFConfiguration *)configuration {
    return self.fetcher.configuration;
}

@end
