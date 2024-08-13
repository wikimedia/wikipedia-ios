import XCTest

final class SharedLibTest: XCTestCase {

    var alt: AltText?

    override func setUpWithError() throws {
        alt = try AltText()
    }

    override func tearDownWithError() throws {
    }

    func testCaptionNoAlt() throws {
        let text = "[[File:Test no alt.jpg|caption here]]"
        let wikitext = "text text " + text + " text text"
        let result = try alt?.missingAltTextLinks(text: wikitext, language: "en")
        XCTAssertEqual(result?.count, 1)
        let link = result?[0]
        XCTAssertEqual(link?.text, text)
        XCTAssertEqual(link?.file, "File:Test no alt.jpg")
        XCTAssertEqual(link?.offset, "text text ".count)
        XCTAssertEqual(link?.length, text.count)
    }

    func testCaptionWithAlt() throws {
        let text = "[[File:Test with alt.jpg|caption here|alt=Cool picture]]"
        let wikitext = "text text " + text + " text text"
        let result = try alt?.missingAltTextLinks(text: wikitext, language: "en")
        XCTAssertEqual(result?.count, 0)
    }
    
    func testCaptionExtract1EN() throws {
        let missingLink = MissingAltTextLink(text: "[[File:Test no alt.jpg|caption here]]", file: "File:Test no alt.jpg", offset: 10, length: 37)
        
        if #available(iOS 16.0, *) {
            do {
                let caption = try missingLink.extractCaption(languageCode: "en")
                XCTAssertEqual(caption, "caption here")
            } catch {
                XCTFail("Failure extracting caption")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func testCaptionExtract2EN() throws {
        // Note: offset and length do not matter for this test
        let missingLink = MissingAltTextLink(text: "[[File:Brechschere-Hund.jpg|thumb|Location of a dog's [[carnassial]]s; the inside of the 4th upper [[premolar]] aligns with the outside of the 1st lower [[Molar (tooth)|molar]], working like scissor blades.]]", file: "File:Brechschere-Hund.jpg", offset: 0, length: 0)
        
        if #available(iOS 16.0, *) {
            do {
                let caption = try missingLink.extractCaption(languageCode: "en")
                XCTAssertEqual(caption, "Location of a dog's carnassials; the inside of the 4th upper premolar aligns with the outside of the 1st lower molar, working like scissor blades.")
            } catch {
                XCTFail("Failure extracting caption")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func testCaptionExtract3EN() throws {
        // Note: offset and length do not matter for this test
        let missingLink = MissingAltTextLink(text: "[[File:Cat skull.jpg|thumb|Cat skull|left|220x220px]]", file: "File:Cat skull.jpg", offset: 0, length: 0)
        
        if #available(iOS 16.0, *) {
            do {
                let caption = try missingLink.extractCaption(languageCode: "en")
                XCTAssertEqual(caption, "Cat skull")
            } catch {
                XCTFail("Failure extracting caption")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func testCaptionExtract4EN() throws {
        // Note: offset and length do not matter for this test
        let missingLink = MissingAltTextLink(text: "[[File:Ann Dunham with father and children.jpg|thumb|left|Obama (right) with grandfather [[Stanley Armour Dunham]], mother [[Ann Dunham]], and half-sister [[Maya Soetoro-Ng|Maya Soetoro]], mid-1970s in [[Honolulu]]]]", file: "File:Ann Dunham with father and children.jpg", offset: 0, length: 0)
        
        if #available(iOS 16.0, *) {
            do {
                let caption = try missingLink.extractCaption(languageCode: "en")
                XCTAssertEqual(caption, "Obama (right) with grandfather Stanley Armour Dunham, mother Ann Dunham, and half-sister Maya Soetoro, mid-1970s in Honolulu")
            } catch {
                XCTFail("Failure extracting caption")
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func testCaptionExtract5EN() throws {
        // Note: offset and length do not matter for this test
        let missingLink = MissingAltTextLink(text: "[[File:Barry Soetoro school record.jpg|thumb|Obama's Indonesian school record in St. Francis of Assisi Catholic Elementary School. Obama was enrolled as \"Barry Soetoro\" (no. 1), and was wrongly recorded as an Indonesian citizen (no. 3) and a Muslim (no. 4).<ref name=\"Suhartono_3/19/2010\">{{Cite news|last=Suhartono|first=Anton|date=March 19, 2010|title=Sekolah di SD Asisi, Obama Berstatus Agama Islam|work=Okezone|url=https://nasional.okezone.com/read/2010/03/19/337/313977/sekolah-di-sd-asisi-obama-berstatus-agama-islam|language=Indonesian|access-date=January 21, 2021|archive-date=January 28, 2021|archive-url=https://web.archive.org/web/20210128041130/https://nasional.okezone.com/read/2010/03/19/337/313977/sekolah-di-sd-asisi-obama-berstatus-agama-islam|url-status=live}}</ref>]]", file: "File:Barry Soetoro school record.jpg", offset: 0, length: 0)
        
        if #available(iOS 16.0, *) {
            do {
                let caption = try missingLink.extractCaption(languageCode: "en")
                XCTAssertEqual(caption, "Obama's Indonesian school record in St. Francis of Assisi Catholic Elementary School. Obama was enrolled as \"Barry Soetoro\" (no. 1), and was wrongly recorded as an Indonesian citizen (no. 3) and a Muslim (no. 4).")
            } catch {
                XCTFail("Failure extracting caption")
            }
        } else {
            // Fallback on earlier versions
        }
    }

}
