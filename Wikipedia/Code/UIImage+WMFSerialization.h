//
//  UIImage+WMFSerialization.h
//  Wikipedia
//
//  Created by Brian Gerstle on 7/1/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (WMFSerialization)

- (NSData *)wmf_pngRepresentation;

- (NSData *)wmf_losslessJPEGRepresentation;

- (NSData *)wmf_dataRepresentationForMimeType:(NSString *)mimeType serializedMimeType:(NSString **)outMimeType;

@end
