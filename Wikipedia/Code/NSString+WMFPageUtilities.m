#import <WMF/NSString+WMFPageUtilities.h>
#import <WMF/WMFRangeUtils.h>
#import <WMF/NSString+WMFExtras.h>

NSString *const WMFReferenceFragmentSubstring = @"ref_";
NSString *const WMFCitationFragmentSubstring = @"cite_note";
NSString *const WMFEndNoteFragmentSubstring = @"endnote_";

@implementation NSString (WMFPageUtilities)

- (BOOL)wmf_isReferenceFragment {
    return [self containsString:WMFReferenceFragmentSubstring];
}

- (BOOL)wmf_isCitationFragment {
    return [self containsString:WMFCitationFragmentSubstring];
}

- (BOOL)wmf_isEndNoteFragment {
    return [self containsString:WMFEndNoteFragmentSubstring];
}

- (NSString *)wmf_unescapedNormalizedPageTitle {
    return [[self stringByRemovingPercentEncoding] wmf_normalizedPageTitle];
}

- (NSString *)wmf_normalizedPageTitle {
    return [[self stringByReplacingOccurrencesOfString:@"_" withString:@" "] precomposedStringWithCanonicalMapping];
}

- (NSString *)wmf_denormalizedPageTitle {
    return [[self stringByReplacingOccurrencesOfString:@" " withString:@"_"] precomposedStringWithCanonicalMapping];
}

@end
