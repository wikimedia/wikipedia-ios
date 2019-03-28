module.exports = function (grunt) {

  grunt.loadNpmTasks( 'grunt-browserify' )
  grunt.loadNpmTasks( 'gruntify-eslint' )
  grunt.loadNpmTasks( 'grunt-contrib-copy' )
  grunt.loadNpmTasks( 'grunt-contrib-less' )

  var allJSFilesInJSFolder = 'js/**/*.js'
  var distFolder = '../wikipedia/assets/'

  grunt.initConfig( {

    browserify: {
      codeMirror: {
        src: ['codemirror/**/codemirror-range-*.js'],
        dest: '../wikipedia/assets/codemirror/codemirror-range-determination-bundle.js'
      },
      distMain: {
        src: [
          'index-main.js',
          allJSFilesInJSFolder,
          '!preview-main.js'
        ],
        dest: `${distFolder}index.js`
      },
      distPreview: {
        src: [
          'preview-main.js',
          'js/utilities.js'
        ],
        dest: `${distFolder}preview.js`
      },
      distAbout: {
        src: [
          'about-main.js'
        ],
        dest: `${distFolder}about.js`
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
          {
            src: 'less/**/*.less',
            dest: `${distFolder}styleoverrides.css`
          }
        ]
      }
    },

    eslint: {
      src: [
        '*.js',
        allJSFilesInJSFolder
      ],
      options: {
        fix: false
      }
    },

    copy: {
      main: {
        files: [
          {
            src: [
              '*.html',
              '*.css',
              'ios.json',
              'languages.json',
              'mainpages.json',
              '*.png',
              '*.pdf'
            ],
            dest: distFolder
          },
          {
            src: 'node_modules/wikimedia-page-library/build/wikimedia-page-library-transform.css',
            dest: `${distFolder}wikimedia-page-library-transform.css`
          },
          {
            src: 'node_modules/wikimedia-page-library/build/wikimedia-page-library-transform.css.map',
            dest: `${distFolder}wikimedia-page-library-transform.css.map`
          },
          {
            expand: true,
            cwd: '../Carthage/Checkouts/wikipedia-ios-codemirror/resources/',
            src: ['**'],
            dest: `${distFolder}codemirror/resources/`
          },
          {
            expand: true,
            cwd: 'codemirror/',
            src: ['**', '!**/*.js'],
            dest: `${distFolder}codemirror/`
          }
        ]
      }
    }
  } )

  grunt.registerTask('default', [
    'eslint',
    'browserify',
    'less',
    'copy'
  ])
}