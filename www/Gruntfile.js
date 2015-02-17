module.exports = function (grunt) {
  var allScriptFiles = "js/*.js";

  var allStyleFiles = [
    "less/*.less"
  ];

  var allHTMLFiles =  "*.html";

  var distFolder = '../wikipedia/assets/';

  grunt.loadNpmTasks( 'grunt-browserify' );
  grunt.loadNpmTasks( 'grunt-contrib-jshint' );
  grunt.loadNpmTasks( 'grunt-contrib-copy' );
  grunt.loadNpmTasks( 'grunt-contrib-less' );

  grunt.initConfig( {
    pkg: grunt.file.readJSON( "package.json" ),

    browserify: {
      dist: {
        src: allScriptFiles,
        dest: distFolder + "bundle.js"
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
          { src: ["less/table.less"], dest: distFolder + "footer.css"},
          { src: ["less/styleoverrides.less"], dest: distFolder + "styleoverrides.css"}
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
        files: [{
          src: ["*.html",
                "*.css",
                "ios.json",
                "languages.json",
                "mainpages.json",
                "*.png"],
          dest: distFolder
        }]
      }
    }
  } );

  grunt.registerTask('default', [/*'jshint',*/ 'browserify', 'less', 'copy']);
};
