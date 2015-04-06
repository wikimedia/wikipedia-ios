#import "WMFImageURLParsing.h"

static NSRegularExpression* WMFImageURLParsingRegex() {
    static NSRegularExpression* imageNameFromURLRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: try to read serialized regex from disk to prevent needless pattern compilation on next app run
        NSError* patternCompilationError;
        imageNameFromURLRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+px-([^.]*\\.[^.]*).*$"
                                                                          options:0
                                                                            error:&patternCompilationError];
        NSCParameterAssert(!patternCompilationError);
    });
    return imageNameFromURLRegex;
}

NSString* WMFParseImageNameFromSourceURL(NSURL* sourceURL)  __attribute__((overloadable)){
    return WMFParseImageNameFromSourceURL(sourceURL.absoluteString);
}

NSString* WMFParseImageNameFromSourceURL(NSString* sourceURL)  __attribute__((overloadable)){
    if (!sourceURL) {
        return nil;
    }
    NSString* fileName = [sourceURL lastPathComponent];
    NSArray* matches   = [WMFImageURLParsingRegex() matchesInString:fileName
                                                            options:0
                                                              range:NSMakeRange(0, [fileName length])];
    return matches.count ? [fileName substringWithRange : [matches[0] rangeAtIndex:1]] : fileName;
}

NSInteger WMFParseSizePrefixFromSourceURL(NSString* sourceURL)  __attribute__((overloadable)){
    if (!sourceURL) {
        return NSNotFound;
    }
    NSString* fileName = [sourceURL lastPathComponent];
    if (!fileName || (fileName.length == 0)) {
        return NSNotFound;
    }
    NSRange range = [fileName rangeOfString:@"px-"];
    if (range.location == NSNotFound) {
        return NSNotFound;
    } else {
        NSInteger result = [fileName substringToIndex:range.location].integerValue;
        return (result == 0) ? NSNotFound : result;
    }
}
