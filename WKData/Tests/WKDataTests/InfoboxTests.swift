import XCTest
@testable import WKData

final class WKWikitextUtilsInfoboxTests: XCTestCase {

    func testEnglishInsertImageWikitextIntoInfoboxTaxobox() throws {

        let imageWikitext = "[[File: Popcorn.jpg | thumb | 220x124px | right ]]"
        let altText = "Popcorn alt text"
        let caption = "Popcorn caption text"

        let originalWikitext = """
                {{Short description|Type of corn kernel which expands and puffs up on heating}}
                {{Other uses}}
                {{pp-move}}
                {{pp-semi-indef}}
                {{Use dmy dates|date=July 2019}}
                {{Taxobox
                | image             =
                | image_caption     =
                | alt               =
                | regnum            = [[Plantae]]
                | unranked_divisio  = [[Angiosperms]]
                | unranked_classis  = [[Monocots]]
                | unranked_ordo     = [[Commelinids]]
                | ordo              = [[Poales]]
                | familia           = [[Poaceae]]
                | genus             = ''[[Zea (plant)|Zea]]''
                | species           = '''''[[Zea mays|Z. mays]]'''''
                | subspecies        = '''''Z. m. everta'''''
                | trinomial         = ''Zea mays everta''
                }}

                '''Popcorn''' (also called '''popped corn''', '''popcorns''', or '''pop-corn''') is a variety of [[Maize|corn]] [[seed|kernel]] which expands and puffs up when heated; the same names also refer to the foodstuff produced by the expansion.

                A popcorn kernel's strong hull contains the seed's hard, starchy shell [[endosperm]] with 14–20% moisture, which turns to steam as the kernel is heated. Pressure from the steam continues to build until the hull ruptures, allowing the kernel to forcefully expand, to 20 to 50 times its original size, and then cool.<ref name="ref5">{{cite web |title=How Popcorn Pops
                |website=Thoughtco.com |author=Michelle Higgins |date=5 May 2017 |url=https://www.thoughtco.com/how-does-popcorn-pop-607429}}</ref>

                Some [[strain (biology)|strains]] of corn ([[Taxonomy (biology)|taxonomized]] as ''Zea mays'') are cultivated specifically as popping corns. The ''Zea mays'' variety ''everta'', a special kind of [[flint corn]], is the most common of these.
            """


        let finalWikitext =  """
                {{Short description|Type of corn kernel which expands and puffs up on heating}}
                {{Other uses}}
                {{pp-move}}
                {{pp-semi-indef}}
                {{Use dmy dates|date=July 2019}}
                {{Taxobox
                | image             = [[File: Popcorn.jpg | thumb | 220x124px | right ]]
                | image_caption     = Popcorn caption text
                | alt               = Popcorn alt text
                | regnum            = [[Plantae]]
                | unranked_divisio  = [[Angiosperms]]
                | unranked_classis  = [[Monocots]]
                | unranked_ordo     = [[Commelinids]]
                | ordo              = [[Poales]]
                | familia           = [[Poaceae]]
                | genus             = ''[[Zea (plant)|Zea]]''
                | species           = '''''[[Zea mays|Z. mays]]'''''
                | subspecies        = '''''Z. m. everta'''''
                | trinomial         = ''Zea mays everta''
                }}

                '''Popcorn''' (also called '''popped corn''', '''popcorns''', or '''pop-corn''') is a variety of [[Maize|corn]] [[seed|kernel]] which expands and puffs up when heated; the same names also refer to the foodstuff produced by the expansion.

                A popcorn kernel's strong hull contains the seed's hard, starchy shell [[endosperm]] with 14–20% moisture, which turns to steam as the kernel is heated. Pressure from the steam continues to build until the hull ruptures, allowing the kernel to forcefully expand, to 20 to 50 times its original size, and then cool.<ref name="ref5">{{cite web |title=How Popcorn Pops
                |website=Thoughtco.com |author=Michelle Higgins |date=5 May 2017 |url=https://www.thoughtco.com/how-does-popcorn-pop-607429}}</ref>

                Some [[strain (biology)|strains]] of corn ([[Taxonomy (biology)|taxonomized]] as ''Zea mays'') are cultivated specifically as popping corns. The ''Zea mays'' variety ''everta'', a special kind of [[flint corn]], is the most common of these.
            """


        let updatedWikitext = try WKWikitextUtils.attempInsertImageWikitextIntoArticleWikitextInfobox(imageWikitext: imageWikitext, caption: caption, altText: altText, into: originalWikitext)
        XCTAssertEqual(finalWikitext, updatedWikitext)


    }
}
