version = '1.0'

# keep stuff that may change for each developer in an external json file to simplify source control
developerConfig = require(__dirname + '/gruntProperties.json')

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
          out: 'dist/barndoors-' + version + '.js'

    clean:
      deleteSource:
        src: [ compiledBaseDir, 'dist' ]

    copy:
      deployToReasonDevDir:
        files: [
          # {expand: true, flatten:true, src: ['dist/*'], dest: '/Users/tfeiler/remotes/ventnorTfeilerReason/global_stock/js/barndoors/', filter: 'isFile'}
          {expand: true, flatten:true, src: ['dist/*'], dest: developerConfig.reasonHome + '/global_stock/js/barndoors/', filter: 'isFile'}
        ]

    exec:
      generateTags:
        command: 'find . -name "*.coffee" | ctags -f coffeeTags -L -'

  )

  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-copy')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-requirejs')
  grunt.loadNpmTasks('grunt-exec')

  grunt.registerTask('default', 'does a complete clean/build/optimize cycle', ['clean:deleteSource', 'coffee:compileSource', 'requirejs:optimize'])
  grunt.registerTask('tags', 'uses Exuberant ctags to create tags file for use with editors like Vim', ['exec:generateTags'])

  grunt.registerTask('deploy', 'does a complete clean/build/optimize cycle and deploys to reason dev dir', () ->
    grunt.task.run('default', 'copy:deployToReasonDevDir')
    # console.log "actual work disabled..."
  )

# data = require(__dirname + '/foo.json')
# console.log "data is [" + data.hello + "]"
###
  fs = require('fs')
  cfgFile = __dirname + '/foo.json'
  console.log "about to read a fiel with [" + fs + "]/[" + cfgFile + "]"
  rawData = fs.readFileSync(cfgFile)
  data = JSON.parse(rawData)
###
