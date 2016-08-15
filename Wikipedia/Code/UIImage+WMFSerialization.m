//
//  UIImage+WMFSerialization.m
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "UIImage+WMFSerialization.h"
#import <AnimatedGIFImageSerialization/AnimatedGIFImageSerialization.h>

@implementation UIImage (WMFSerialization)

- (NSData *)wmf_pngRepresentation {
    return UIImagePNGRepresentation(self);
}

- (NSData *)wmf_losslessJPEGRepresentation {
    return UIImageJPEGRepresentation(self, 1.0);
}

- (NSData *)wmf_gifRepresentation {
    return UIImageAnimatedGIFRepresentation(self);
}

- (NSData *)wmf_dataRepresentationForMimeType:(NSString *)mimeType
                           serializedMimeType:(NSString *__autoreleasing *)outMimeType {
    if ([mimeType hasSuffix:@"jpeg"]) {
        if (*outMimeType) {
            *outMimeType = @"image/jpeg";
        }
        return [self wmf_losslessJPEGRepresentation];
    } else if ([mimeType hasSuffix:@"png"]) {
        if (*outMimeType) {
            *outMimeType = @"image/png";
        }
        return [self wmf_pngRepresentation];
    } else if ([mimeType hasSuffix:@"gif"]) {
        NSData *data = [self wmf_gifRepresentation];
        if (data) {
            if (*outMimeType) {
                *outMimeType = @"image/gif";
            }
            return data;
        }
    }

    DDLogWarn(@"Unknown Image Type %@, falling back on PNG", mimeType);
    *outMimeType = @"image/png";
    return [self wmf_pngRepresentation];
}

@end
