#import <WMF/MWKDataObject.h>
#import <WMF/NSDateFormatter+WMFExtensions.h>

@implementation MWKDataObject

- (id)dataExport;
{
    @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                   reason:@"dataExport not implemented"
                                 userInfo:@{}];
}

#pragma mark - string methods

- (NSString *)optionalString:(NSString *)key dict:(NSDictionary *)dict {
    id obj = dict[key];
    if (obj == nil) {
        return nil;
    } else if ([obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    } else {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"expected string, got something else"
                                     userInfo:@{@"key": key}];
    }
}

- (NSString *)requiredString:(NSString *)key dict:(NSDictionary *)dict {
    return [self requiredString:key dict:dict allowEmpty:YES];
}

- (NSString *)requiredString:(NSString *)key dict:(NSDictionary *)dict allowEmpty:(BOOL)allowEmpty {
    NSString *str = [self optionalString:key dict:dict];
    if (str == nil || (str.length == 0 && !allowEmpty)) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"expected string, got nothing"
                                     userInfo:@{@"key": key}];
    } else {
        return str;
    }
}

#pragma mark - number methods

- (NSNumber *)optionalNumber:(NSString *)key dict:(NSDictionary *)dict {
    id obj = dict[key];
    if (obj == nil) {
        return nil;
    } else if ([obj isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)obj;
    } else if ([obj isKindOfClass:[NSString class]]) {
        // PHP is often fuzzy and sometimes gives us strings when we wanted integers.
        return [self numberWithString:(NSString *)obj];
    } else {
        @throw [NSException exceptionWithName:@"MWKDataObjectException" reason:@"expected string or nothing, got something else" userInfo:nil];
    }
}

- (NSNumber *)requiredNumber:(NSString *)key dict:(NSDictionary *)dict {
    NSNumber *num = [self optionalNumber:key dict:dict];
    if (num == nil) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required number field"
                                     userInfo:@{@"key": key}];
    } else {
        return num;
    }
}

- (NSNumber *)numberWithString:(NSString *)str {
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

- (NSDate *)optionalDate:(NSString *)key dict:(NSDictionary *)dict {
    NSString *str = [self optionalString:key dict:dict];
    if (str == nil) {
        return nil;
    } else {
        return [self getDateFromIso8601DateString:str];
    }
}

- (NSDate *)requiredDate:(NSString *)key dict:(NSDictionary *)dict {
    NSDate *date = [self optionalDate:key dict:dict];
    if (date == nil) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required date field"
                                     userInfo:@{@"key": key}];
    } else {
        return date;
    }
}

#pragma mark - date methods

- (NSDate *)getDateFromIso8601DateString:(NSString *)string {
    return [[NSDateFormatter wmf_iso8601Formatter] dateFromString:string];
}

- (NSString *)iso8601DateString:(NSDate *)date {
    return [[NSDateFormatter wmf_iso8601Formatter] stringFromDate:date];
}

#pragma mark - dictionary methods

- (NSDictionary *)optionalDictionary:(NSString *)key dict:(NSDictionary *)dict {
    id obj = dict[key];
    if (obj == nil) {
        return nil;
    } else if ([obj isKindOfClass:[NSArray class]]) {
        // PHP likes to output empty associative arrays as empty JSON arrays,
        // which become empty NSArrays.
        return @{};
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)obj;
    } else {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"expected dictionary, got something else"
                                     userInfo:@{@"key": key}];
    }
}

- (NSDictionary *)requiredDictionary:(NSString *)key dict:(NSDictionary *)dict {
    NSDictionary *obj = [self optionalDictionary:key dict:dict];
    if (obj == nil) {
        @throw [NSException exceptionWithName:@"MWKDataObjectException"
                                       reason:@"missing required dictionary field"
                                     userInfo:@{@"key": key}];
    } else {
        return obj;
    }
}

@end
