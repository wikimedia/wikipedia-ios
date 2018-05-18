#import "ToCInteractionFunnel.h"

static NSString *const kAppInstallIdKey = @"appInstallID";

@implementation ToCInteractionFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppToCInteraction
    self = [super initWithSchema:@"MobileWikiAppToCInteraction"
                         version:10375484];
    return self;
}

- (NSDictionary *)preprocessData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [eventData mutableCopy];
    dict[kAppInstallIdKey] = [self wmf_appInstallID];
    return [NSDictionary dictionaryWithDictionary:dict];
}

- (void)logOpen {
    [self log:@{@"action": @"open"}];
}

- (void)logClose {
    [self log:@{@"action": @"close"}];
}

- (void)logClick {
    [self log:@{@"action": @"click"}];
}

@end
