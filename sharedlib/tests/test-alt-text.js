let {missingAltTextLinks} = require('../alt-text.js');

let testCases = [
    {
        wikiText: '[[File:Foobar.jpg]]',
        desc: 'Inline image, no alt or caption',
        expected: [
            {
                text: '[[File:Foobar.jpg]]',
                offset: 0,
                length: '[[File:Foobar.jpg]]'.length,
                file: 'File:Foobar.jpg',
                alt: null,
            }
        ]
    },
    {
        wikiText: '[[Image:Foobar.jpg]]',
        desc: 'Inline image, no alt or caption',
        expected: [
            {
                text: '[[Image:Foobar.jpg]]',
                offset: 0,
                length: '[[Image:Foobar.jpg]]'.length,
                file: 'Image:Foobar.jpg',
                alt: null,
            }
        ]
    },
    {
        wikiText: '[[File:Foobar.jpg|alt=Painting depicting a gazebo]]',
        desc: 'Inline image, explicit alt',
        expected: [],
    },
    {
        wikiText: '[[File:Foobar.jpg|Painting depicting a gazebo]]',
        desc: 'Inline image, implicit alt as caption',
        expected: [
            {
                text: '[[File:Foobar.jpg|Painting depicting a gazebo]]',
                offset: 0,
                length: '[[File:Foobar.jpg|Painting depicting a gazebo]]'.length,
                file: 'File:Foobar.jpg',
                alt: null,
            }
        ]
    },
    {
        wikiText: '[[File:Foobar.jpg|thumb|On display]]',
        desc: 'Thumbnail image, no alt, has caption',
        expected: [
            {
                text: '[[File:Foobar.jpg|thumb|On display]]',
                offset: 0,
                length: '[[File:Foobar.jpg|thumb|On display]]'.length,
                file: 'File:Foobar.jpg',
                alt: null,
            }
        ]
    },
    {
        wikiText: '[[File:Foobar.jpg|thumb|alt=Painting depicting a gazebo]]',
        desc: 'Thumbnail image, explicit alt, no caption',
        expected: []
    },
    {
        wikiText: '[[File:Foobar.jpg|thumb|alt=Painting depicting a gazebo|On display]]',
        desc: 'Thumbnail image, explicit alt, has caption',
        expected: []
    },
    {
        wikiText: '[[Image:Foobar.jpg|thumb|alt=Painting depicting a gazebo|On display]]',
        desc: 'Thumbnail image, explicit alt, has caption',
        expected: []
    },
    {
        wikiText: '[[File:Foobar.jpg|alt=]]',
        desc: 'Inline image, explicit empty alt',
        expected: []
    },
    {
        wikiText: '[[File:Foobar.jpg|thumb|alt=]]',
        desc: 'Thumbnail image, explicit empty alt, no caption',
        expected: []
    },
    {
        wikiText: '[[File:Foobar.jpg|thumb|alt=|On display]]',
        desc: 'Thumbnail image, explicit empty alt, has caption',
        expected: []
    },
    {
        wikiText: 'bla bla [[File:Foobar.jpg|nice stuff]] and [[File:Baz.jpg|utter madness|alt=Baz]]',
        desc: 'Two links, one no alt one with alt',
        expected: [
            {
                text: '[[File:Foobar.jpg|nice stuff]]',
                offset: 'bla bla '.length,
                length: '[[File:Foobar.jpg|nice stuff]]'.length,
                file: 'File:Foobar.jpg',
                alt: null,
            }
        ]
    },
];

let failures = 0;
for (let {wikiText, count, desc, expected} of testCases) {
    let missing = missingAltTextLinks(wikiText, 'en', ['File', 'Image'], ['alt']);
    if (JSON.stringify(expected) !== JSON.stringify(missing)) {
        console.error("MISMATCH", wikiText);
        console.error('expected', expected);
        console.error('got', missing);
        failures++;
    } else {
        console.log("OK", wikiText);
        console.error('got', missing);
    }
}
if (failures > 0) {
    process.exit(1);
}
