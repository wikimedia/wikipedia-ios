/*jshint node:true */
module.exports = function ( grunt ) {
  var allScriptFiles = "www/js/**/*.js";

  var distFolder = 'Wikipedia/assets/';

  grunt.loadNpmTasks( 'grunt-contrib-jshint' );
  grunt.loadNpmTasks( 'grunt-jsonlint' );
  grunt.loadNpmTasks( 'grunt-browserify' );
  grunt.loadNpmTasks( 'grunt-contrib-copy' );
  grunt.loadNpmTasks( 'grunt-contrib-less' );

  grunt.initConfig( {

    jshint: {
      options: {
        jshintrc: true
      },
      all: [
        '.',
        '!node_modules/**'
      ]
    },

    jsonlint: {
      all: [
        '**/*.json',
        '!node_modules/**'
      ]
    },

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
          { src: ["www/less/**/*.less"], dest: distFolder + "styleoverrides.css"}
        ]
      }
    },

    copy: {
      main: {
        files: [{
          src: ["www/*.html",
                "www/*.css",
                "www/ios.json",
                "www/languages.json",
                "www/mainpages.json",
                "www/*.png"],
          dest: distFolder
        }]
      }
    }
  } );

  grunt.registerTask( 'test', [ 'jshint', 'jsonlint', 'browserify', 'less', 'copy' ] );
  grunt.registerTask( 'default', 'test' );
};
