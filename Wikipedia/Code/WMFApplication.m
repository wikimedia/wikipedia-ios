
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "WMFApplication.h"

@implementation WMFApplication

- (void)sendEvent:(UIEvent *)event
{
    if ( event.type == UIEventTypeMotion && event.subtype == UIEventSubtypeMotionShake ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"shakeNotification" object:nil];
    }

    [super sendEvent:event];
}

@end
