const MobileHTML = require('./mobileapps/lib/mobile/MobileHTML')
const MobileViewHTML = require('./mobileapps/lib/mobile/MobileViewHTML')

async function convertParsoidDocumentToMobileHTML(doc, metadata = {}) {
    const mobileHTML = await MobileHTML.promise(doc, metadata)
    if (metadata.mw) {
        mobileHTML.addMediaWikiMetadata(metadata.mw)
    }
    return mobileHTML.doc.documentElement.outerHTML
}

async function convertParsoidHTMLToMobileHTML(parsoidHTML, metadata = {}) {
    const parser = new DOMParser()
    const doc = parser.parseFromString(parsoidHTML, 'text/html')
    return await convertParsoidDocumentToMobileHTML(doc, metadata)
}

async function convertMobileViewJSONToMobileHTML(mobileViewJSON, metadata = {}) {
    const parser = new DOMParser()
    const doc = parser.parseFromString('<html><head><meta charset="utf-8"><title></title></head><body></body></html>', 'text/html')
    const mobileView = mobileViewJSON.mobileview
    // for some reason this is expected in both the param and in the metadata obj
    metadata.mobileview = mobileView
    const parsoidDocument = MobileViewHTML.convertToParsoidDocument(doc, mobileView, metadata)
    return await convertParsoidDocumentToMobileHTML(parsoidDocument, metadata)
}

const mw = {
    "pageid": 4269567,
    "ns": 0,
    "title": "Dog",
    "contentmodel": "wikitext",
    "pagelanguage": "en",
    "pagelanguagehtmlcode": "en",
    "pagelanguagedir": "ltr",
    "touched": "2019-12-06T03:48:17Z",
    "lastrevid": 929485161,
    "length": 126950,
    "protection": [
        {
            "type": "edit",
            "level": "autoconfirmed",
            "expiry": "infinity"
        },
        {
            "type": "move",
            "level": "sysop",
            "expiry": "infinity"
        }
    ],
    "restrictiontypes": [
        "edit",
        "move"
    ],
    "description": "domestic animal",
    "descriptionsource": "central"
}

async function testParsoid() {
    const url = "https://en.wikipedia.org/api/rest_v1/page/html/Dog"
    const meta = {
      baseURI: "http://localhost:6927/en.wikipedia.org/v1/",
      mw
    }
    const response = await fetch(url)
    const parsoidHTML = await response.text()
    const mobileHTML = await PCSHTMLConverter.convertParsoidHTMLToMobileHTML(parsoidHTML, meta)
    return mobileHTML
}

async function testMobileView() {
    const url = "https://en.wikipedia.org/w/api.php?action=mobileview&format=json&page=Dog&sections=all&prop=text%7Csections%7Clanguagecount%7Cthumb%7Cimage%7Cid%7Crevision%7Cdescription%7Cnamespace%7Cnormalizedtitle%7Cdisplaytitle%7Cprotection%7Ceditable&sectionprop=toclevel%7Cline%7Canchor&noheadings=1&thumbwidth=1024&origin=*"
    const meta = {
      domain: "en.wikipedia.org",
      baseURI: "http://localhost:6927/en.wikipedia.org/v1/",
      mw
    }
    const response = await fetch(url)
    const mobileViewJSON = await response.json()
    const mobileHTML = await PCSHTMLConverter.convertMobileViewJSONToMobileHTML(mobileViewJSON, meta)
    return mobileHTML
}

module.exports = {
    convertParsoidHTMLToMobileHTML,
    convertMobileViewJSONToMobileHTML,
    testParsoid,
    testMobileView
}
