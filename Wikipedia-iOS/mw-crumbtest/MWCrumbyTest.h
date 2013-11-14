//  Created by Monte Hurd on 11/10/13.

/*
This object makes it easier to automate higher-level testing of more complex async 
code (dependent NSOperations presently). Think unit testing but for things which 
are not so easily reduced to nice little units. Unity testing? This approach 
employs a "bread crumb" metaphor to define an execution "trail" which is then 
verified.
*/

#define CRUMBY_STATUS_DISPLAY_NAMES @{\
        @(CRUMBY_STATUS_READY_TO_HIKE) : @"READY TO HIKE",\
        @(CRUMBY_STATUS_ON_TRAIL) : @"ON TRAIL",\
        @(CRUMBY_STATUS_OFF_TRAIL) : @"OFF TRAIL",\
        @(CRUMBY_STATUS_ARRIVED_SAFELY) : @"ARRIVED SAFELY"\
}

typedef enum {
    CRUMBY_STATUS_READY_TO_HIKE = 0,
    CRUMBY_STATUS_ON_TRAIL = 1,
    CRUMBY_STATUS_OFF_TRAIL = 2,
    CRUMBY_STATUS_ARRIVED_SAFELY = 3
} MWCrumbTestStatus;

@interface MWCrumbyTest : NSObject

@property (assign, readonly) MWCrumbTestStatus status;
@property (copy, readonly) NSString *trailSoFar;
@property (copy, readonly) NSString *expectedTrail;
@property (assign, readonly) SEL kickoffSelector;
@property (copy, readonly) NSString *description;

/*
Needed a simple way to confirm that async operation(s) for a given task had executed in a 
pre-determined order. Tell this object's init what testing method to execute to set the 
test in motion. Then within the callbacks of the various async things that kicked off,
drop "crumbs". Init is also told what trail (of crumbs) it should expect and the order of
this expected trail is then verified by this button object as these crumbs are dropped as 
the execution progresses.
*/
-(id)initWithTrailhead:(SEL)kickOffSelector target:(id)target trailExpected:(NSString *)trailExpected description:(NSString *)description;

// Drop crumbs at various points to create a trail which will be hiked. Ensure the order
// and location of drops conforms to the trailExpected passed to init.

// Upper case crumbs must be encountered in order for status to go CRUMBY_STATUS_ARRIVED_SAFELY.
// Lower case crumbs must be encountered, but the order in which they are encountered doesn't matter.
// (lower case crumbs handy, say, for ensuring dealloc was called, even if we don't care or can't
// control exactly when this happens)
-(void)dropCrumb:(NSString *)crumb;

// Begin executing the kickoff selector passed to init. As the execution encounters
// "dropCrumb" statements this object will verify they are encountered in the order
// specified in the init's "trailExpected" argument. This object's status and
// expectedTrail properties may be observed to monitor trail progression.
-(void)hike;

-(void)reset;

-(NSString *)displayNameForStatus:(MWCrumbTestStatus)status;

@end
