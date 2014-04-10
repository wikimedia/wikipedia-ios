
module.exports = function ( grunt ) {
    var allScriptFiles = [
        "js/*.js"
    ];
    var allStyleFiles = [
        "less/*.less"
    ];
    var allHTMLFiles = [
        "index.html"
    ];

    grunt.initConfig( {
        pkg: grunt.file.readJSON( "package.json" ),

        browserify: {
            dist: {
                files: { "bundle.js": [ "js/*.js" ]
                }
            }
        },
        less: {
            all: {
                files: [
                    { src: ["less/pagestyles.less"], dest: "styles.css"}
                ]
            }
        },
        jshint: {
            allFiles: allScriptFiles,
            options: {
                jshintrc: ".jshintrc"
            }
        },
        copy: {
            main: {
                files: [
                    // App files
                    {src: ["bundle.js", "index.html", "styles.css"], dest: "../wikipedia/assets/"},
                    // Images
                    {src: ["images/*"], dest: "../wikipedia/assets/"}
                ]
            }
        },
        watch: {
            scripts: {
                files: allScriptFiles.concat( allStyleFiles ).concat( allHTMLFiles ),
                tasks: ["default"]
            }
        },
        // Remove temp files from www folder
        clean : {
            main : {
                src : [ "styles.css", "bundle.js"]
            }
        }
    } );

    grunt.loadNpmTasks( 'grunt-browserify' );
    grunt.loadNpmTasks( 'grunt-contrib-jshint' );
    grunt.loadNpmTasks( 'grunt-contrib-copy' );
    grunt.loadNpmTasks( 'grunt-contrib-watch' );
    grunt.loadNpmTasks( 'grunt-contrib-less' );
    grunt.loadNpmTasks( 'grunt-contrib-clean' );

    grunt.registerTask( 'default', [ 'browserify', 'less', 'copy', 'clean' /*, 'watch' */] );
};
