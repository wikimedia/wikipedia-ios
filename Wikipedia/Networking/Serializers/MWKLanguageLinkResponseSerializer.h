//
//  MWKLanguageLinkResponseSerializer.h
//  Wikipedia
//
//  Created by Brian Gerstle on 6/8/15.
//  Copyright (c) 2015 Wikimedia Foundation. All rights reserved.
//

#import "WMFApiJsonResponseSerializer.h"

/// Serializer which parses langlink query responses into @c MWKLanguageLink objects.
@interface MWKLanguageLinkResponseSerializer : WMFApiJsonResponseSerializer

@end
