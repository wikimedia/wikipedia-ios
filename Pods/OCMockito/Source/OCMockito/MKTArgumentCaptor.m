//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTArgumentCaptor.h"

#import "MKTCapturingMatcher.h"


@interface MKTArgumentCaptor ()
@property (readonly, nonatomic, strong) MKTCapturingMatcher *matcher;
@end

@implementation MKTArgumentCaptor

- (instancetype)init
{
    self = [super init];
    if (self)
        _matcher = [[MKTCapturingMatcher alloc] init];
    return self;
}

- (id)capture
{
    return self.matcher;
}

- (id)value
{
    return [self.matcher lastValue];
}

- (NSArray *)allValues
{
    return [self.matcher allValues];
}

@end
