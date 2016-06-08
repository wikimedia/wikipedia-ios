#import "NSMutableString+WMFImageProxy.h"
#import "NSString+WMFImageProxy.h"

@implementation NSMutableString (WMFImageProxy)

- (void)wmf_replaceImgTagSrcValuesWithLocalhostProxyURLs{
    NSError *error;
    NSString *pattern = @"(<img.+src\\=)(?:\")(.+?)(?:\")(.+?)(\\>)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSInteger offset = 0;
    for (NSTextCheckingResult* result in [regex matchesInString:self
                                                        options:0
                                                          range:NSMakeRange(0, [self length])]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        /*
         NSString* entireTag = [regex replacementStringForResult:result
         inString:self
         offset:offset
         template:@"$0"];
         */
        
        NSString* opener = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$1"];
        
        NSString* srcURL = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$2"];
        
        NSString* other = [regex replacementStringForResult:result
                                                   inString:self
                                                     offset:offset
                                                   template:@"$3"];
        
        NSString* closer = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$4"];
        
        NSMutableString* mutableOther = [other mutableCopy];
        [mutableOther wmf_replaceImgTagSrcsetValuesWithLocalhostProxyURLs];
        
        NSString* replacement = [NSString stringWithFormat:@"%@\"%@\"%@%@",
                                 opener,
                                 [srcURL wmf_stringWithLocalhostProxyPrefix],
                                 mutableOther,
                                 closer
                                 ];
        
        [self replaceCharactersInRange:resultRange withString:replacement];
        
        offset += [replacement length] - resultRange.length;
    }
}

- (void)wmf_replaceImgTagSrcsetValuesWithLocalhostProxyURLs{
    NSError *error;
    NSString *pattern = @"(.+?)(srcset\\=)(?:\")(.+?)(?:\")(.+?)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSInteger offset = 0;
    for (NSTextCheckingResult* result in [regex matchesInString:self
                                                        options:0
                                                          range:NSMakeRange(0, [self length])]) {
        
        NSRange resultRange = [result range];
        resultRange.location += offset;
        
        /*
         NSString* entireTag = [regex replacementStringForResult:result
         inString:self
         offset:offset
         template:@"$0"];
         */
        
        NSString* before = [regex replacementStringForResult:result
                                                    inString:self
                                                      offset:offset
                                                    template:@"$1"];
        
        NSString* srcsetKey = [regex replacementStringForResult:result
                                                       inString:self
                                                         offset:offset
                                                       template:@"$2"];
        
        NSString* srcsetValue = [regex replacementStringForResult:result
                                                         inString:self
                                                           offset:offset
                                                         template:@"$3"];
        
        NSString* after = [regex replacementStringForResult:result
                                                   inString:self
                                                     offset:offset
                                                   template:@"$4"];
        
        
        NSString* replacement = [NSString stringWithFormat:@"%@%@\"%@\"%@",
                                 before,
                                 srcsetKey,
                                 [srcsetValue wmf_srcsetValueWithLocalhostProxyPrefixes],
                                 after
                                 ];
        
        [self replaceCharactersInRange:resultRange withString:replacement];
        
        offset += [replacement length] - resultRange.length;
    }
}

@end
