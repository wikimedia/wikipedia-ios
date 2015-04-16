//
//  MWKDataObject.m
//  MediaWikiKit
//
//  Created by Brion on 10/14/14.
//  Copyright (c) 2014 Wikimedia Foundation. All rights reserved.
//

#import "MediaWikiKit.h"
#import "NSDateFormatter+WMFExtensions.h"

@implementation MWKDataObject

- (id)dataExport;
{
    @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                   reason:@"dataExport not implemented"
                                 userInfo:@{}];
}

#pragma mark - string methods

- (NSString*)optionalString:(NSString*)key dict:(NSDictionary*)dict {
    if(![dict isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    id obj = dict[key];
    if (![obj isKindOfClass:[NSString class]]) {
        obj = nil;
    }
    return obj;
}

- (NSString*)requiredString:(NSString*)key dict:(NSDictionary*)dict {
    NSString* str = [self optionalString:key dict:dict];
    return str;
}

#pragma mark - number methods


- (NSNumber*)optionalNumber:(NSString*)key dict:(NSDictionary*)dict {
    if(![dict isKindOfClass:[NSDictionary class]]){
        return nil;
    }

    id obj = dict[key];
    if ([obj isKindOfClass:[NSString class]]) {
        obj = [self numberWithString:(NSString*)obj];
    }

    if (![obj isKindOfClass:[NSNumber class]]) {
        obj = nil;
    }

    return obj;
}

- (NSNumber*)requiredNumber:(NSString*)key dict:(NSDictionary*)dict {
    NSNumber* num = [self optionalNumber:key dict:dict];
    return num;
}

- (NSNumber*)numberWithString:(NSString*)str {
    if(![str isKindOfClass:[NSString class]]){
        return nil;
    }
    if ([str rangeOfString:@"."].location != NSNotFound ||
        [str rangeOfString:@"e"].location != NSNotFound) {
        double val = [str doubleValue];
        return [NSNumber numberWithDouble:val];
    } else {
        int val = [str intValue];
        return [NSNumber numberWithInt:val];
    }
}

#pragma mark - date methods

- (NSDate*)optionalDate:(NSString*)key dict:(NSDictionary*)dict {
    NSString* str = [self optionalString:key dict:dict];
    if (str == nil) {
        return nil;
    }
    return [self getDateFromIso8601DateString:str];
}

- (NSDate*)requiredDate:(NSString*)key dict:(NSDictionary*)dict {
    NSDate* date = [self optionalDate:key dict:dict];
    return date;
}

#pragma mark - date methods

- (NSDate*)getDateFromIso8601DateString:(NSString*)string {
    return [[NSDateFormatter wmf_iso8601Formatter] dateFromString:string];
}

- (NSString*)iso8601DateString:(NSDate*)date {
    return [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:date];
}

#pragma mark - dictionary methods

- (NSDictionary*)optionalDictionary:(NSString*)key dict:(NSDictionary*)dict {
    if(![dict isKindOfClass:[NSDictionary class]]){
        return nil;
    }

    id obj = dict[key];
    if ([obj isKindOfClass:[NSArray class]]) {
        obj = @{};
    }
    return obj;
}

- (NSDictionary*)requiredDictionary:(NSString*)key dict:(NSDictionary*)dict {
    NSDictionary* obj = [self optionalDictionary:key dict:dict];
    return obj;
}

@end
