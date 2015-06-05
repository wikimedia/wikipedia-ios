//  Created by Jaikumar Bhambhwani on 11/10/12.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "NSString+Extras.h"
#import "TFHpple.h"
#import <CommonCrypto/CommonDigest.h>
#import "SessionSingleton.h"
#import "MWLanguageInfo.h"
#import "NSDateFormatter+WMFExtensions.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (Extras)

- (NSString*)wmf_safeSubstringToIndex:(NSUInteger)index {
    return [self substringToIndex:MIN(self.length, index)];
}

- (NSString*)wmf_safeSubstringFromIndex:(NSUInteger)index {
    return [self substringFromIndex:MIN(index, self.length - 1)];
}

- (NSString*)wmf_UTF8StringWithPercentEscapes {
    return (__bridge_transfer id)CFURLCreateStringByAddingPercentEscapes(0,
                                                                         (__bridge CFStringRef)self,
                                                                         0,
                                                                         (__bridge CFStringRef)@";/?:@&=$+{}<>,",
                                                                         kCFStringEncodingUTF8);
}

- (NSString*)wmf_schemelessURL {
    NSRange dividerRange = [self rangeOfString:@"://"];
    if (dividerRange.location == NSNotFound) {
        return self;
    }
    NSUInteger divide = NSMaxRange(dividerRange) - 2;
    //NSString *scheme = [self substringToIndex:divide];
    NSString* path = [self substringFromIndex:divide];
    return path;
}

- (NSString*)wmf_mimeTypeForExtension {
    // From: http://stackoverflow.com/a/21858677/135557
    NSString* UTI = (__bridge_transfer NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)self, NULL);
    return (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
}

- (NSDate*)wmf_iso8601Date {
    return [[NSDateFormatter wmf_iso8601Formatter] dateFromString:self];
}

- (NSString*)wmf_stringByRemovingHTML {
    // Strips html from string with xpath / hpple.
    if (!self || (self.length == 0)) {
        return self;
    }
    NSData* stringData      = [self dataUsingEncoding:NSUTF8StringEncoding];
    TFHpple* parser         = [TFHpple hppleWithHTMLData:stringData];
    NSArray* textNodes      = [parser searchWithXPathQuery:@"//text()"];
    NSMutableArray* results = @[].mutableCopy;
    for (TFHppleElement* node in textNodes) {
        if (node.isTextNode) {
            [results addObject:node.raw];
        }
    }

    NSString* result = [results componentsJoinedByString:@""];

    // Also decode any "&amp;" strings.
    result = [result stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

    return result;
}

- (NSString*)wmf_randomlyRepeatMaxTimes:(NSUInteger)maxTimes;
{
    float (^ rnd)() = ^(){
        return (float)(rand() % (maxTimes - 1) + 1);
    };

    NSString* randStr = [@"" stringByPaddingToLength:rnd()* [self length] withString:self startingAtIndex:0];

    return [NSString stringWithFormat:@"<%@>", [randStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
}

- (NSString*)wmf_stringByReplacingUndrescoresWithSpaces {
    return [self stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (NSString*)wmf_stringByReplacingSpacesWithUnderscores {
    return [self stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

- (NSString*)wmf_stringByCapitalizingFirstCharacter {
    // Capitalize first character of WikiData description.
    if (self.length > 1) {
        NSString* firstChar      = [self substringToIndex:1];
        NSString* remainingChars = [self substringFromIndex:1];
        NSLocale* locale         = [self getLocaleForCurrentSearchDomain];
        firstChar = [firstChar capitalizedStringWithLocale:locale];
        return [firstChar stringByAppendingString:remainingChars];
    }
    return self;
}

- (NSLocale*)getLocaleForCurrentSearchDomain {
    NSString* domain = [SessionSingleton sharedInstance].currentArticleSite.language;

    MWLanguageInfo* languageInfo = [MWLanguageInfo languageInfoForCode:domain];

    NSString* code = languageInfo.code;

    NSLocale* locale = nil;

    if (code && [[NSLocale availableLocaleIdentifiers] containsObject:code]) {
        locale = [[NSLocale alloc] initWithLocaleIdentifier:code];
    }

    if (!locale) {
        locale = [NSLocale currentLocale];
    }

    return locale;
}

- (BOOL)wmf_containsString:(NSString*)string {
    return [self wmf_containsString:string options:NSLiteralSearch];
}

- (BOOL)wmf_caseInsensitiveContainsString:(NSString*)string {
    return [self wmf_containsString:string options:NSCaseInsensitiveSearch];
}

- (BOOL)wmf_containsString:(NSString*)string options:(NSStringCompareOptions)options {
    return [self rangeOfString:string options:options].location == NSNotFound ? NO : YES;
}

- (BOOL)wmf_isEqualToStringIgnoringCase:(NSString*)string {
    return (NSOrderedSame == [self caseInsensitiveCompare:string]);
}

@end
