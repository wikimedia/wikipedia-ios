#import "ToCInteractionFunnel.h"

@implementation ToCInteractionFunnel

- (id)init {
    // https://meta.wikimedia.org/wiki/Schema:MobileWikiAppToCInteraction
    self = [super initWithSchema:@"MobileWikiAppToCInteraction"
                         version:10375484];
    return self;
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
