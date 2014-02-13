//  Created by Adam Baso on 2/11/14.

#import "WikipediaAppUtils.h"

@implementation WikipediaAppUtils

+(NSString*) appVersion
{
    NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
    return [NSString stringWithFormat: @"iOS-%@-%@-%@",
            [appInfo objectForKey: @"CFBundleDisplayName"],
            [appInfo objectForKey:@"CFBundleShortVersionString"],
            [appInfo objectForKey: @"CFBundleVersion"]
            ];
}

@end
