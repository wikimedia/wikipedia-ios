#import <WMF/WMFImageURLParsing.h>
#import <WMF/WMFLogging.h>
#import <WMF/WMF-Swift.h>

static NSRegularExpression *WMFImageURLParsingRegex(void) {
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
        DDLogError(@"Unable to parse source URL with too few path components: %@", pathComponents);
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
            // stringBeforePx is "200" for the following:
            // upload.wikimedia.org/wikipedia/commons/thumb/4/41/200px-Potato.jpg/
            result = stringBeforePx.integerValue;
        } else {
            // stringBeforePx is "page1-240" for the following:
            // upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg
            NSString *stringAfterDash = [stringBeforePx substringFromIndex:lastDashRange.location + 1];
            result = stringAfterDash.integerValue;
        }
        return (result == 0) ? NSNotFound : result;
    }
}

NSString *WMFOriginalImageURLStringFromURLString(NSString *URLString) {
    NSURLComponents *components = [NSURLComponents componentsWithString:URLString];
    if (!components) {
        return URLString;
    }

    NSString *path = components.percentEncodedPath;
    if ([path containsString:@"/thumb/"]) {
        path = [[path stringByDeletingLastPathComponent] stringByReplacingOccurrencesOfString:@"/thumb/" withString:@"/"];
        components.percentEncodedPath = path;
    }

    return components.string;
}

NSString *WMFChangeImageSourceURLSizePrefix(NSString *sourceURL, NSInteger newSizePrefix) __attribute__((overloadable)) {
    if (!sourceURL) {
        return nil;
    }

    if (newSizePrefix < 1) {
        newSizePrefix = 1;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:sourceURL];
    if (!components) {
        return sourceURL;
    }

    NSString *path = components.percentEncodedPath;

    NSString *wikipediaString = @"/wikipedia/";
    NSRange wikipediaStringRange = [path rangeOfString:wikipediaString];

    if (path.length == 0 || wikipediaStringRange.location == NSNotFound) {
        return sourceURL;
    }

    NSString *pathAfterWikipedia = [path substringFromIndex:wikipediaStringRange.location + wikipediaStringRange.length];
    NSRange rangeOfSlashAfterWikipedia = [pathAfterWikipedia rangeOfString:@"/"];
    if (rangeOfSlashAfterWikipedia.location == NSNotFound) {
        return sourceURL;
    }

    NSString *site = [pathAfterWikipedia substringToIndex:rangeOfSlashAfterWikipedia.location];
    if (site.length == 0) {
        return sourceURL;
    }

    NSString *lastPathComponent = [path lastPathComponent];

    if (WMFParseSizePrefixFromSourceURL(path) == NSNotFound) {
        NSString *sizeVariantLastPathComponent = [NSString stringWithFormat:@"%lupx-%@", (unsigned long)newSizePrefix, lastPathComponent];

        NSString *lowerCasePathExtension = [[path pathExtension] lowercaseString];
        if ([lowerCasePathExtension isEqualToString:@"pdf"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"page1-%@.jpg", sizeVariantLastPathComponent];
        } else if ([lowerCasePathExtension isEqualToString:@"tif"] || [lowerCasePathExtension isEqualToString:@"tiff"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"lossy-page1-%@.jpg", sizeVariantLastPathComponent];
        } else if ([lowerCasePathExtension isEqualToString:@"svg"]) {
            sizeVariantLastPathComponent = [NSString stringWithFormat:@"%@.png", sizeVariantLastPathComponent];
        }

        NSString *newPath = [[path stringByAppendingString:@"/"] stringByAppendingString:sizeVariantLastPathComponent];
        newPath = [newPath stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@%@/", wikipediaString, site]
                                                     withString:[NSString stringWithFormat:@"%@%@/thumb/", wikipediaString, site]];

        components.percentEncodedPath = newPath;
    } else {
        NSRange rangeOfLastPathComponent = NSMakeRange(
            [path rangeOfString:lastPathComponent
                        options:NSBackwardsSearch]
                .location,
            lastPathComponent.length);
        NSString *newPath = [WMFImageURLParsingRegex() stringByReplacingMatchesInString:path
                                                                                options:NSMatchingAnchored
                                                                                  range:rangeOfLastPathComponent
                                                                           withTemplate:[NSString stringWithFormat:@"$1$2%lupx-$3", (unsigned long)newSizePrefix]];
        components.percentEncodedPath = newPath;
    }

    return components.string;
}
