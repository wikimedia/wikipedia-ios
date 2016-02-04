#import "WMFImageURLParsing.h"
#import "NSString+WMFExtras.h"

static NSRegularExpression* WMFImageURLParsingRegex() {
    static NSRegularExpression* imageNameFromURLRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: try to read serialized regex from disk to prevent needless pattern compilation on next app run
        NSError* patternCompilationError;
        imageNameFromURLRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+px-(.*)"
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
    NSArray* pathComponents = [sourceURL componentsSeparatedByString:@"/"];
    if (pathComponents.count < 2) {
        DDLogWarn(@"Unable to parse source URL with too few path components: %@", pathComponents);
        return nil;
    }

    /*
       For URLs in form "https://upload.wikimedia.org/.../Filename.jpg/XXXpx-Filename.jpg" try to acquire filename via
       the second to last path component, which has only one extension.
     */
    NSString* filenameComponent = pathComponents[pathComponents.count - 2];
    if ([[filenameComponent.pathExtension wmf_asMIMEType] hasPrefix:@"image"]) {
        return filenameComponent;
    }

    NSString* thumbOrFileComponent = [pathComponents lastObject];
    NSArray* matches               = [WMFImageURLParsingRegex() matchesInString:thumbOrFileComponent
                                                                        options:0
                                                                          range:NSMakeRange(0, [thumbOrFileComponent length])];

    if (matches.count > 0) {
        // Found a "XXXpx-" prefix, extract substring and return as filename
        return [thumbOrFileComponent substringWithRange:[matches[0] rangeAtIndex:1]];
    } else {
        // No "XXXpx-" prefix found, return the entire last component, as the URL is (probably) in the form //.../Filename.jpg
        return thumbOrFileComponent;
    }
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
