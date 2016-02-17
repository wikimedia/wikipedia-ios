//
//  NSCalendar+WMFCommonCalendars.m
//  Wikipedia
//
//  Created by Brian Gerstle on 2/12/16.
//  Copyright © 2016 Wikimedia Foundation. All rights reserved.
//

#import "NSCalendar+WMFCommonCalendars.h"

@implementation NSCalendar (WMFCommonCalendars)

+ (instancetype)wmf_utcGregorianCalendar {
    static dispatch_once_t onceToken;
    static NSCalendar* utcGregorianCalendar;
    dispatch_once(&onceToken, ^{
        utcGregorianCalendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        utcGregorianCalendar.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return utcGregorianCalendar;
}

@end
