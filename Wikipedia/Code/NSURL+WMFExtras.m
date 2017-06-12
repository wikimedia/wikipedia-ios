#import <WMF/NSURL+WMFExtras.h>
#import <WMF/NSString+WMFExtras.h>

@implementation NSURL (WMFExtras)

+ (nullable instancetype)wmf_optionalURLWithString:(nullable NSString *)string {
    return string.length ? [NSURL URLWithString:string] : nil;
}

- (BOOL)wmf_isEqualToIgnoringScheme:(NSURL *)url {
    return [self.wmf_schemelessURLString isEqualToString:url.wmf_schemelessURLString];
}

- (nullable NSString *)wmf_schemelessURLString {
    if (self.scheme.length) {
        return [self.absoluteString wmf_safeSubstringFromIndex:self.scheme.length + 1];
    } else {
        return self.absoluteString;
    }
}

- (nullable NSURL *)wmf_schemelessURL {
    if (self.scheme.length) {
        NSString *string = [self wmf_schemelessURLString];
        if (string.length > 0) {
            return [NSURL URLWithString:string];
        } else {
            return nil;
        }
    } else {
        return self;
    }
}

- (NSString *)wmf_mimeTypeForExtension {
    // HAX: These SVG URLs don't have an extension, so make them a special case
    if ([self.path containsString:@"/render/svg/"]) {
        return @"image/svg+xml";
    }
    return [self.pathExtension wmf_asMIMEType];
}

- (BOOL)wmf_isSchemeless {
    return self.scheme.length == 0;
}

- (instancetype)wmf_urlByPrependingSchemeIfSchemeless:(NSString *)scheme {
    NSParameterAssert(scheme.length);
    if (![self wmf_isSchemeless]) {
        return self;
    } else {
        NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self resolvingAgainstBaseURL:YES];
        components.scheme = scheme;
        return components.URL;
    }
}

- (instancetype)wmf_urlByPrependingSchemeIfSchemeless {
    return [self wmf_urlByPrependingSchemeIfSchemeless:@"https"];
}

- (BOOL)wmf_isIntraPageFragment {
    return ([self.path isEqualToString:@"/"] && self.fragment);
}

@end
