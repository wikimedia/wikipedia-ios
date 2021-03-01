module.exports = function (grunt) {

  grunt.loadNpmTasks( 'gruntify-eslint' )
  grunt.loadNpmTasks( 'grunt-contrib-copy' )
  grunt.loadNpmTasks( 'grunt-contrib-less' )

  var distFolder = '../wikipedia/assets/'

  grunt.initConfig( {

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
        '*.js'
      ],
      options: {
        fix: true
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
              '*.png',
              '*.pdf',
              'about.js',
              'index.js'
            ],
            dest: distFolder
          },
          {
            expand: true,
            cwd: '../CodeMirror/wikipedia-ios-codemirror/resources/',
            src: ['**'],
            dest: `${distFolder}codemirror/resources/`
          },
          {
            expand: true,
            cwd: 'codemirror/',
            src: ['**'],
            dest: `${distFolder}codemirror/`
          }
        ]
      }
    }
  } )

  grunt.registerTask('default', [
    'eslint',
    'less',
    'copy'
  ])
}