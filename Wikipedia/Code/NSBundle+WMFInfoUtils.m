#import <WMF/NSBundle+WMFInfoUtils.h>

@implementation NSBundle (WMFInfoUtils)

- (NSString *)wmf_bundleName {
    return [self objectForInfoDictionaryKey:@"CFBundleName"];
}

#pragma mark - Version Info

- (NSString *)wmf_bundleIdentifier {
    return [self objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)wmf_bundleVersion {
    return [self objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)wmf_appVersion {
    NSString *build = [self wmf_bundleVersion] ?: @"0";
    NSString *shortVersion = [self objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.0.0";
    NSString *datePart = [shortVersion stringByReplacingOccurrencesOfString:@"." withString:@"-"];

    NSString *environment;
    if ([self isTestFlight]) {
        environment = @"beta";
    } else if ([[self wmf_bundleIdentifier] hasSuffix:@"wikipedia"]) {
        environment = @"r";
    } else {
        environment = @"alpha";
    }

    return [NSString stringWithFormat:@"%@-%@-%@", build, environment, datePart];
}

- (NSString *)wmf_merchantID {
    return [self objectForInfoDictionaryKey:@"MerchantID"];
}

- (BOOL)isTestFlight {
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSString *receiptName = [receiptURL lastPathComponent];
    return [receiptName isEqualToString:@"sandboxReceipt"];
}

@end
