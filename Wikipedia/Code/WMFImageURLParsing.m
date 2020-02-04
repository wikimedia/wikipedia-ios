#import <WMF/WMFImageURLParsing.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMF-Swift.h>

static NSRegularExpression *WMFImageURLParsingRegex() {
    static NSRegularExpression *imageNameFromURLRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: try to read serialized regex from disk to prevent needless pattern compilation on next app run
        NSError *patternCompilationError;
        imageNameFromURLRegex = [NSRegularExpression regularExpressionWithPattern:@"^(lossy-|lossless-)?(page\\d+-)?\\d+px-(.*)"
                                                                          options:0
                                                                            error:&patternCompilationError];
        NSCParameterAssert(!patternCompilationError);
    });
    return imageNameFromURLRegex;
}

BOOL WMFIsThumbURLString(NSString *URLString) {
    return ([URLString rangeOfString:@"/thumb/"].location != NSNotFound);
}

NSString *WMFParseImageNameFromSourceURL(NSURL *sourceURL) __attribute__((overloadable)) {
    return WMFParseImageNameFromSourceURL(sourceURL.absoluteString);
}

NSString *WMFParseImageNameFromSourceURL(NSString *sourceURL) __attribute__((overloadable)) {
    if (!sourceURL) {
        return nil;
    }
    NSArray *pathComponents = [sourceURL componentsSeparatedByString:@"/"];
    if (pathComponents.count < 2) {
        DDLogWarn(@"Unable to parse source URL with too few path components: %@", pathComponents);
        return nil;
    }

    if (!WMFIsThumbURLString(sourceURL)) {
        return [sourceURL lastPathComponent];
    } else {
        return pathComponents[pathComponents.count - 2];
    }
}

NSString *WMFParseUnescapedNormalizedImageNameFromSourceURL(NSString *sourceURL) __attribute__((overloadable)) {
    NSString *imageName = WMFParseImageNameFromSourceURL(sourceURL);
    NSString *normalizedImageName = [imageName wmf_unescapedNormalizedPageTitle];
    return normalizedImageName;
}

NSString *WMFParseUnescapedNormalizedImageNameFromSourceURL(NSURL *sourceURL) __attribute__((overloadable)) {
    return WMFParseUnescapedNormalizedImageNameFromSourceURL(sourceURL.absoluteString);
}

NSInteger WMFParseSizePrefixFromSourceURL(NSURL *sourceURL) __attribute__((overloadable)) {
    return WMFParseSizePrefixFromSourceURL(sourceURL.absoluteString);
}

NSInteger WMFParseSizePrefixFromSourceURL(NSString *sourceURL) __attribute__((overloadable)) {
    if (!sourceURL) {
        return NSNotFound;
    }
    if (!WMFIsThumbURLString(sourceURL)) {
        return NSNotFound;
    }
    NSString *fileName = [sourceURL lastPathComponent];
    if (!fileName || (fileName.length == 0)) {
        return NSNotFound;
    }
    NSRange pxRange = [fileName rangeOfString:@"px-"];
    if (pxRange.location == NSNotFound) {
        return NSNotFound;
    } else {
        NSString *stringBeforePx = [fileName substringToIndex:pxRange.location];
        NSRange lastDashRange = [stringBeforePx rangeOfString:@"-" options:NSBackwardsSearch];
        NSInteger result = NSNotFound;
        if (lastDashRange.location == NSNotFound) {
            //stringBeforePx is "200" for the following:
            //upload.wikimedia.org/wikipedia/commons/thumb/4/41/200px-Potato.jpg/
            result = stringBeforePx.integerValue;
        } else {
            //stringBeforePx is "page1-240" for the following:
            //upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg
            NSString *stringAfterDash = [stringBeforePx substringFromIndex:lastDashRange.location + 1];
            result = stringAfterDash.integerValue;
        }
        return (result == 0) ? NSNotFound : result;
    }
}

NSString *WMFOriginalImageURLStringFromURLString(NSString *URLString) {
    if ([URLString containsString:@"/thumb/"]) {
        URLString = [[URLString stringByDeletingLastPathComponent] stringByReplacingOccurrencesOfString:@"/thumb/" withString:@"/"];
    }
    return URLString;
}

NSString *WMFChangeImageSourceURLSizePrefix(NSString *sourceURL, NSInteger newSizePrefix) __attribute__((overloadable)) {
    if (newSizePrefix < 1) {
        newSizePrefix = 1;
    }

    NSString *wikipediaString = @"/wikipedia/";
    NSRange wikipediaStringRange = [sourceURL rangeOfString:wikipediaString];

    if (sourceURL.length == 0 || (wikipediaStringRange.location == NSNotFound)) {
        return sourceURL;
    }

    NSString *urlAfterWikipedia = [sourceURL substringFromIndex:wikipediaStringRange.location + wikipediaStringRange.length];
    NSRange rangeOfSlashAfterWikipedia = [urlAfterWikipedia rangeOfString:@"/"];
    if (rangeOfSlashAfterWikipedia.location == NSNotFound) {
        return sourceURL;
    }

    NSString *site = [urlAfterWikipedia substringToIndex:rangeOfSlashAfterWikipedia.location];
    if (site.length == 0) {
        return sourceURL;
    }

    NSString *lastPathComponent = [sourceURL lastPathComponent];

    if (WMFParseSizePrefixFromSourceURL(sourceURL) == NSNotFound) {
        NSString *sizeVariantLastPathComponent = [NSString stringWithFormat:@"%lupx-%@", (unsigned long)newSizePrefix, lastPathComponent];

        NSString *lowerCasePathExtension = [[sourceURL pathExtension] lowercaseString];
        if ([lowerCasePathExtension isEqualToString:@"pdf"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"page1-%@.jpg", sizeVariantLastPathComponent];
        } else if ([lowerCasePathExtension isEqualToString:@"tif"] || [lowerCasePathExtension isEqualToString:@"tiff"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"lossy-page1-%@.jpg", sizeVariantLastPathComponent];
        } else if ([lowerCasePathExtension isEqualToString:@"svg"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"%@.png", sizeVariantLastPathComponent];
        }

        NSString *urlWithSizeVariantLastPathComponent = [[sourceURL stringByAppendingString:@"/"] stringByAppendingString:sizeVariantLastPathComponent];

        NSString *urlWithThumbPath = [urlWithSizeVariantLastPathComponent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@/", wikipediaString, site] withString:[NSString stringWithFormat:@"%@%@/thumb/", wikipediaString, site]];

        return urlWithThumbPath;
    } else {
        NSRange rangeOfLastPathComponent =
            NSMakeRange(
                [sourceURL rangeOfString:lastPathComponent
                                 options:NSBackwardsSearch]
                    .location,
                lastPathComponent.length);
        return
            [WMFImageURLParsingRegex() stringByReplacingMatchesInString:sourceURL
                                                                options:NSMatchingAnchored
                                                                  range:rangeOfLastPathComponent
                                                           withTemplate:[NSString stringWithFormat:@"$1$2%lupx-$3", (unsigned long)newSizePrefix]];
    }
}
