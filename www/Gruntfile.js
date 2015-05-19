module.exports = function (grunt) {
  var allScriptFiles = "js/**/*.js";

  var distFolder = '../wikipedia/assets/';

  grunt.loadNpmTasks( 'grunt-browserify' );
  grunt.loadNpmTasks( 'grunt-contrib-jshint' );
  grunt.loadNpmTasks( 'grunt-contrib-copy' );
  grunt.loadNpmTasks( 'grunt-contrib-less' );

  grunt.initConfig( {

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
          { src: ["less/**/*.less"], dest: distFolder + "styleoverrides.css"}
        ]
      }
    },

    jshint: {
      allFiles: allScriptFiles,
      options: {
        jshintrc: true
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

  grunt.registerTask('default', ['jshint', 'browserify', 'less', 'copy']);
};
