module.exports = function (grunt) {
  var allJSFilesInJSFolder = 'js/**/*.js'

  var distFolder = '../wikipedia/assets/'

  grunt.loadNpmTasks( 'grunt-browserify' )
  grunt.loadNpmTasks( 'gruntify-eslint' )
  grunt.loadNpmTasks( 'grunt-contrib-copy' )
  grunt.loadNpmTasks( 'grunt-contrib-less' )

  grunt.initConfig( {

    browserify: {
      distMain: {
        src: ['index-main.js', allJSFilesInJSFolder, '!preview-main.js'],
        dest: distFolder + 'index.js'
      },
      distPreview: {
        src: ['preview-main.js', 'js/utilities.js'],
        dest: distFolder + 'preview.js'
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
          { src: ['less/**/*.less', 'node_modules/wikimedia-page-library/build/wikimedia-page-library-transform.css'], dest: distFolder + 'styleoverrides.css'}
        ]
      }
    },

    eslint: {
      src: ['*.js', allJSFilesInJSFolder],
      options: {
        fix: false
      }
    },

    copy: {
      main: {
        files: [{
          src: ['*.html',
            '*.css',
            'ios.json',
            'languages.json',
            'mainpages.json',
            '*.png'],
          dest: distFolder
        }]
      }
    }
  } )

  grunt.registerTask('default', ['eslint', 'browserify', 'less', 'copy'])
}