// These are approximations for the link portion of the parser
// and won't catch all actual links, but should catch most or all
// manually written links and file invocations.
const start = "\\[\\[";
const end = "\\]\\]";
const nonLink = "[^\\[\\]\\|]+";
const innerLink = `\\[\\[${nonLink}(?:\|${nonLink})*\]\]`;
const webLink = `\\[${nonLink}\\]`;
const span = `(?:${nonLink}|${innerLink}|${webLink})+`;

// Capture the inside part of the link
const linksRegEx = new RegExp(
    `${start}(${span}(?:\\|${span})*)${end}`,
    "dmg"
);

// @fixme we need to support localized variants;
// fetch them into a .json for use here, or pass
// them in from the Swift side maybe?
const fileRegEx = /^\s*(?:Image|File):.*/i;
const altRegEx = /^\s*alt\s*=\s*(?:[^\|\]]*)$/i;

function parseLink(offset, length, text, language) {
    let bits = text.split( /\|/ );
    let link = {
        text: '[[' + text + ']]',
        offset,
        length,
        file: null,
        alt: null,
    };
    for (let bit of bits) {
        if (bit.match(fileRegEx)) {
            link.file = bit;
        } else if (bit.match(altRegEx)) {
            link.alt = bit;
        }
    }
    return link;
}

function parseLinks(text, language) {
    let matches = text.matchAll(linksRegEx);
    let bits = [];
    for (let m of matches) {
        let offset = m.indices[0][0];
        let link = parseLink(offset, m[0].length, m[1], language);
        bits.push(link);
    }
    return bits;
}

/**
 * Look for file links/invocations with no alt text.
 *
 * @param {string} text input wikitext
 * @param {string} language code
 * @returns {Array} list of {text, offset, length, file, alt} of matching links
 */
function missingAltTextLinks(text, language) {
    return parseLinks(text, language).filter((link) => {
        if (link.file === null) {
            // Not a file link.
            return false;
        }
        if (link.alt !== null) {
            // Has alt text specified
            return false;
        }
        // Note: strictly speaking a surrounding ARIA role can prevent
        // the need here, but this isn't detected in our usage.
        // We assume these will mostly live in templates and won't come
        // up here often.
        return true;
    });
}

module.exports = {
    missingAltTextLinks
};
