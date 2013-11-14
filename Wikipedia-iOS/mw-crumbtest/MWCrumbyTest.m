//  Created by Monte Hurd on 11/10/13.

#import "MWCrumbyTest.h"

@interface MWCrumbyTest()
{
    id kickoffTarget_;
}

@property (copy, readwrite) NSString *statusDescription;
@property (assign, readwrite) MWCrumbTestStatus status;
@property (copy, readwrite) NSString *expectedTrail;
@property (copy, readwrite) NSString *trailSoFar;
@property (copy, readwrite) NSString *description;
@property (assign, readwrite) SEL kickoffSelector;

@end

@implementation MWCrumbyTest

#pragma mark - Init

// Be sure to call init on the main thread
-(id)initWithTrailhead:(SEL)kickOffSelector target:(id)target trailExpected:(NSString *)trailExpected description:(NSString *)description
{
    self = [super init];
    if (self) {
        _trailSoFar = @"";
        kickoffTarget_ = target;
        self.kickoffSelector = kickOffSelector;
        self.expectedTrail = trailExpected;
        self.description = description;
        self.status = CRUMBY_STATUS_READY_TO_HIKE;

        // Ensure any changes to trailSoFar cause status to be updated accordingly
        NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
        [self addObserver:self forKeyPath:@"trailSoFar" options:options context:nil];
    }
    return self;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateStatus];
}

#pragma mark - Test kickoff

-(void)hike
{
    [self resetAndKickOffSelector];
}

#pragma mark - Reset

-(void)reset
{
    self.trailSoFar = @"";
}

-(void)resetAndKickOffSelector
{
    //[[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        [self reset];
    //    [kickoffTarget_ performSelector:self.kickoffSelector withObject:self afterDelay:0];
    //}];

    [kickoffTarget_ performSelectorOnMainThread:self.kickoffSelector withObject:self waitUntilDone:NO];
}

#pragma mark - Status update

-(NSString *)displayNameForStatus:(MWCrumbTestStatus)status
{
    return CRUMBY_STATUS_DISPLAY_NAMES[@(status)];
}

-(void)updateStatus
{
    NSString *(^sortStringCharacters)(NSString *) = ^NSString*(NSString *str){
        if (str == nil || str.length == 0) return @"";
        NSMutableArray *characters = [[NSMutableArray alloc] initWithCapacity:[str length]];
        for (uint i = 0; i < [str length]; i++) {
            NSString *ichar  = [NSString stringWithFormat:@"%c", [str characterAtIndex:i]];
            [characters addObject:ichar];
        }
        [characters sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        return [characters componentsJoinedByString:@""];
    };

    MWCrumbTestStatus status = CRUMBY_STATUS_READY_TO_HIKE;

    status = [self areTrailSoFarCrumbsInExpectedOrder] ? CRUMBY_STATUS_ON_TRAIL : CRUMBY_STATUS_OFF_TRAIL;

    if (status == CRUMBY_STATUS_ON_TRAIL) {
        NSString *lowercaseExpectedTrailCrumbs = [self lowercaseLettersFromString:self.expectedTrail];
        NSString *lowercaseTrailSoFarCrumbs = [self lowercaseLettersFromString:self.trailSoFar];
        NSString *uppercaseExpectedTrailCrumbs = [self uppercaseLettersFromString:self.expectedTrail];
        NSString *uppercaseTrailSoFarCrumbs = [self uppercaseLettersFromString:self.trailSoFar];
        if (
            [sortStringCharacters(lowercaseExpectedTrailCrumbs) isEqualToString:sortStringCharacters(lowercaseTrailSoFarCrumbs)]
                &&
            [uppercaseExpectedTrailCrumbs isEqualToString:uppercaseTrailSoFarCrumbs]
        ) {
            status = CRUMBY_STATUS_ARRIVED_SAFELY;
        }
    }else if (self.trailSoFar.length == 0) {
        status = CRUMBY_STATUS_READY_TO_HIKE;
    }

    [self setStatus:status];
}

-(NSString *)uppercaseLettersFromString:(NSString *)string
{
    NSString *output = @"";
    for (uint i = 0; i < [string length]; i++) {
        unichar thisChar = [string characterAtIndex:i];
        if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:thisChar]) {
            //output = [output stringByAppendingString:[NSString stringWithFormat:@"%c", thisChar]];
            output = [output stringByAppendingString:[[NSString alloc] initWithCharacters:&thisChar length:1]];
        }
    }
    return output;
}

-(NSString *)lowercaseLettersFromString:(NSString *)string
{
    NSString *output = @"";
    for (uint i = 0; i < [string length]; i++) {
        unichar thisChar = [string characterAtIndex:i];
        if ([[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:thisChar]) {
            //output = [output stringByAppendingString:[NSString stringWithFormat:@"%c", thisChar]];
            output = [output stringByAppendingString:[[NSString alloc] initWithCharacters:&thisChar length:1]];
        }
    }
    return output;
}

-(BOOL)areTrailSoFarCrumbsInExpectedOrder
{
    NSString *uppercaseExpectedTrailCrumbs = [self uppercaseLettersFromString:self.expectedTrail];
    NSString *uppercaseTrailSoFarCrumbs = [self uppercaseLettersFromString:self.trailSoFar];

    NSRange range = [uppercaseExpectedTrailCrumbs rangeOfString:uppercaseTrailSoFarCrumbs options:NSCaseInsensitiveSearch];
    if (range.location != NSNotFound){
        if (range.location == 0) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Drop crumb

-(void)dropCrumb:(NSString *)crumb
{
    NSAssert(crumb.length == 1, @"Crumbs must be single character!");
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^ {
        //NSLog(@"DROPPED CRUMB %@", crumb);
        self.trailSoFar = (!self.trailSoFar) ? crumb : [self.trailSoFar stringByAppendingString:crumb];
    }];
}

@end
