#import <WMF/MWKImage+CanonicalFilenames.h>
#import <WMF/NSArray+WMFMapping.h>
#import <WMF/WMFLogging.h>

@implementation MWKImage (CanonicalFilenames)

+ (NSArray *)mapFilenamesFromImages:(NSArray<MWKImage *> *)images {
    return [images wmf_mapAndRejectNil:^id(MWKImage *image) {
        NSString *canonicalFilename = image.canonicalFilename;
        if (canonicalFilename.length) {
            return [@"File:" stringByAppendingString:canonicalFilename];
        } else {
            DDLogWarn(@"Unable to form canonical filename from image: %@", image.sourceURLString);
            return nil;
        }
    }];
}

@end
