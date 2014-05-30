compiledBaseDir = 'compiled'

module.exports = (grunt) ->
  grunt.initConfig(
    coffee:
      compileSource:
        cwd: 'src/coffee'
        src: [ '**/*.coffee' ]
        dest: compiledBaseDir + '/js'
        expand: true
        options:
          sourceMap: true
        ext: '.js'

    requirejs:
      optimize:
        options:
          baseUrl: compiledBaseDir + '/js'
          optimize: 'uglify2'
          findNestedDependencies: true
          generateSourceMaps: true
          preserveLicenseComments: false
          name: 'main'
          out: 'dist/barndoors-optimized.js'

    clean:
      deleteSource:
        src: [ compiledBaseDir, 'dist' ]

    exec:
      generateTags:
        command: 'find . -name "*.coffee" | ctags -f coffeeTags -L -'

  )

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-requirejs')
  grunt.loadNpmTasks('grunt-exec')

  grunt.registerTask('default', 'does a complete clean/build/optimize cycle', ['clean:deleteSource', 'coffee:compileSource', 'requirejs:optimize'])
  grunt.registerTask('tags', 'uses Exuberant ctags to create tags file for use with editors like Vim', ['exec:generateTags'])
