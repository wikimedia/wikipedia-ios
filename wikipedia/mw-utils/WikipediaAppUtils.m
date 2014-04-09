//  Created by Adam Baso on 2/11/14.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

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
