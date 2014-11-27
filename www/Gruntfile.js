
module.exports = function ( grunt ) {
    var allScriptFiles = [
        "js/*.js"
    ];
    var allStyleFiles = [
        "less/*.less"
    ];
    var allHTMLFiles = [
        "index.html",
        "preview.html",
        "abusefilter.html"
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
                options: {
                    compress: true,
                    yuicompress: true,
                    optimization: 2
                },
                files: [
                    { src: ["less/langbutton.less", "less/lastmod.less"], dest: "footer.css"},
                    { src: ["less/styleoverrides.less"], dest: "styleoverrides.css"}
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
                    {src: ["index.html", "preview.html", "abusefilter.html", "about.html", "bundle.js", "footer.css", "styleoverrides.css"], dest: "../wikipedia/assets/"}
                ]
            },
            files: {
                cwd: 'images',  // folder to copy
                src: '**/*',    // copy all files and subfolders
                dest: '../wikipedia/assets/images', // destination folder
                expand: true    // required when using cwd
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
                src : [ "footer.css", "bundle.js", "styleoverrides.css"]
            }
        }
    } );

    grunt.loadNpmTasks( 'grunt-browserify' );
    grunt.loadNpmTasks( 'grunt-contrib-jshint' );
    grunt.loadNpmTasks( 'grunt-contrib-copy' );
    grunt.loadNpmTasks( 'grunt-contrib-watch' );
    grunt.loadNpmTasks( 'grunt-contrib-less' );
    grunt.loadNpmTasks( 'grunt-contrib-clean' );

    /*grunt.registerTask( 'default', [ 'browserify', 'less', 'copy', 'clean', 'watch'] );*/
    /*grunt.registerTask( 'default', [ 'browserify', 'less', 'copy', 'clean'] );*/
    grunt.registerTask( 'default', [ 'browserify', 'less', 'copy', 'clean'] );
};
