//
//  MWKImageInfoSerializationTest.m
//  Wikipedia
//
//  Created by Brian Gerstle on 11/30/15.
//  Copyright © 2015 Wikimedia Foundation. All rights reserved.
//

@import Quick;
@import Nimble;

#import "MWKImageInfoResponseSerializer.h"

QuickSpecBegin(MWKImageInfoSerializationTest)

    describe(@"JSON serialization", ^{
      it(@"should have expected properties from an example payload", ^{
        NSData *fixtureData = [[self wmf_bundle] wmf_dataFromContentsOfFile:@"ImageInfo" ofType:@"json"];
        NSError *error;
        MWKImageInfo *info = [[[MWKImageInfoResponseSerializer serializer] responseObjectForResponse:nil
                                                                                                data:fixtureData
                                                                                               error:&error] firstObject];
        expect(error).to(beNil());
        expect(info.imageDescription)
            .to(equal(@"Farm building after sunset near Hvolsvöllur, Suðurland, Iceland."));
        expect(info.canonicalPageTitle)
            .to(equal(@"File:Caseta cerca de Hvolsv\u00f6llur, Su\u00f0urland, Islandia, 2014-08-16, DD 213.JPG"));
        expect(info.canonicalFileURL.absoluteString)
            .to(equal(@"https://upload.wikimedia.org/wikipedia/commons/4/4c/Caseta_cerca_de_Hvolsv%C3%B6llur%2C_Su%C3%B0urland%2C_Islandia%2C_2014-08-16%2C_DD_213.JPG"));
        expect(info.filePageURL.absoluteString)
            .to(equal(@"https://commons.wikimedia.org/wiki/File:Caseta_cerca_de_Hvolsv%C3%B6llur,_Su%C3%B0urland,_Islandia,_2014-08-16,_DD_213.JPG"));
        expect(info.imageThumbURL.absoluteString)
            .to(equal(@"https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Caseta_cerca_de_Hvolsv%C3%B6llur%2C_Su%C3%B0urland%2C_Islandia%2C_2014-08-16%2C_DD_213.JPG/640px-Caseta_cerca_de_Hvolsv%C3%B6llur%2C_Su%C3%B0urland%2C_Islandia%2C_2014-08-16%2C_DD_213.JPG"));
        expect(info.owner).to(equal(@"Diego Delso"));
        expect(@(info.imageSize.width)).to(equal(@5332));
        expect(@(info.imageSize.height)).to(equal(@2487));
        expect(@(info.thumbSize.width)).to(equal(@640));
        expect(@(info.thumbSize.height)).to(equal(@299));

        expect(info.license.shortDescription).to(equal(@"CC BY-SA 4.0"));
        expect(info.license.URL.absoluteString)
            .to(equal(@"http://creativecommons.org/licenses/by-sa/4.0"));
        expect(info.license.code).to(equal(@"cc-by-sa-4.0"));
      });
    });

QuickSpecEnd