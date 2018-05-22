#import <WMF/NSDictionary+WMFCommonParams.h>
#import <WMF/WMFNumberOfExtractCharacters.h>
#import <WMF/UIScreen+WMFImageWidth.h>

@implementation NSDictionary (WMFCommonParams)

+ (instancetype)wmf_titlePreviewRequestParameters {
    return [self wmf_titlePreviewRequestParametersWithExtractLength:WMFNumberOfExtractCharacters
                                                         imageWidth:[[UIScreen mainScreen] wmf_leadImageWidthForScale]];
}

+ (instancetype)wmf_titlePreviewRequestParametersWithExtractLength:(NSUInteger)extractLength
                                                        imageWidth:(NSNumber *)imageWidth {
    NSParameterAssert(imageWidth);
    NSMutableDictionary *defaults =
        [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                         @"", @"continue",
                                         @"json", @"format",
                                         @"query", @"action",
                                         @"description|pageimages|pageprops|revisions", @"prop",
                                         // pageprops
                                         @"ns|disambiguation|displaytitle", @"ppprop",
                                         // pageimage
                                         @"thumbnail", @"piprop",
                                         //@"any", @"pilicense",
                                         imageWidth, @"pithumbsize",
                                         // revision
                                         @(1), @"rrvlimit",
                                         @"ids", @"rvprop",
                                         nil];

    if (extractLength > 0) {
        defaults[@"explaintext"] = @"";
        defaults[@"exintro"] = @YES;
        defaults[@"exchars"] = @(extractLength);
        defaults[@"prop"] = [defaults[@"prop"] stringByAppendingString:@"|extracts"];
    }

    return defaults;
}

@end
