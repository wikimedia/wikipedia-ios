//  OCMockito by Jon Reid, http://qualitycoding.org/about/
//  Copyright 2015 Jonathan M. Reid. See LICENSE.txt

#import "MKTCapturingMatcher.h"


@interface MKTCapturingMatcher ()
@property (readonly, nonatomic, strong) NSMutableArray *arguments;
@end

@implementation MKTCapturingMatcher

- (instancetype)init
{
    self = [super initWithDescription:@"<Capturing argument>"];
    if (self)
        _arguments = [[NSMutableArray alloc] init];
    return self;
}

- (void)captureArgument:(id)arg
{
    if (!arg)
        arg = [NSNull null];
    [self.arguments addObject:arg];
}

- (NSArray *)allValues
{
    return self.arguments;
}

- (id)lastValue
{
    if ([self noArgumentWasCaptured])
        return [self throwNoArgumentException];
    return [self convertNilArgument:[self.arguments lastObject]];
}

- (BOOL)noArgumentWasCaptured
{
    return [self.arguments count] == 0;
}

- (id)throwNoArgumentException
{
    @throw [NSException exceptionWithName:@"NoArgument"
                                       reason:@"No argument value was captured!\n"
                                              "You might have forgotten to use [argument capture] in verify()"
                                     userInfo:nil];
}

- (id)convertNilArgument:(id)arg
{
    if (arg == [NSNull null])
        arg = nil;
    return arg;
}

@end
