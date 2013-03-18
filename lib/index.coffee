stitch = require 'stitch'
fs = require 'fs'
path = require 'path'
util = require 'util'
async = require 'async'
wrench = require 'wrench'
jade = require 'jade'
_ = require 'underscore'
md = require('node-markdown').Markdown
UglifyJS = require 'uglify-js'

merge = require './utils/merge'

Lexer = require('coffee-script/lib/coffee-script/lexer').Lexer

lexer = new Lexer()

handleQuotes = (string) ->
  # Might as well use CoffeeScript's lexer to handle the quotes in the html
  lexer.makeString string, "'", true

module.exports =

  loadBuilders: (root, options, callback) ->

    sourceMapOut = '.stitch_source'

    merge.mergeOptions root, options, (merged) ->

      { identifier, output, paths, testPaths, dependencies, vendorDependencies, testDependencies, images } = merged

      paths.reverse()
      testPaths.reverse()

      paths = _.uniq paths, false, (path) -> _.last path.split 'node_modules/'

      compilers =

        jade: (module, filename) ->
          source = fs.readFileSync(filename, 'utf8')
          source = "module.exports = " + jade.compile(source, compileDebug: false, client: true) + ";"
          module._compile(source, filename)

        md: (module, filename) ->
          source = fs.readFileSync(filename, 'utf8')
          source = "module.exports = #{handleQuotes md source};"
          module._compile(source, filename)

      pkg = stitch.createPackage { paths, dependencies, identifier, compilers }

      testPackage = stitch.createPackage
        paths: _.flatten [testPaths, paths]
        identifier: identifier
        dependencies: _.flatten [dependencies, testDependencies]
        compilers: compilers

      buildStitch = (callback) ->

        if appPath = output.app

          fs.mkdir path.dirname(appPath), ->

            pkg.compile (err, source, sourceMap) ->

              throw err if err

              fs.writeFile sourceMapOut, JSON.stringify(sourceMap), (err) ->
                throw err if err
                console.log "Created #{sourceMapOut}"

              fs.writeFile output.app, source, (err) ->

                throw err if err

                console.log "Compiled #{output.app}"

                if output.minified

                  uglyOptions = {}

                  minifiedPath = output.minified

                  if _.isObject output.minified

                    minifiedPath = output.minified.out

                    if output.minified.sourceMap
                      uglyOptions.outSourceMap = "app.js"

                  minified = UglifyJS.minify output.app, uglyOptions

                  fs.writeFile minifiedPath, minified.code, (err) ->

                    throw err if err

                    console.log "Minified #{minifiedPath}"

                    if sourceMap = output.minified?.sourceMap

                      fs.writeFile sourceMap, minified.map, (err) ->

                        throw err if err

                        console.log "Created source map #{sourceMap}"

                        callback?()

                    else
                      callback?()

                else
                  callback?()

      buildTest = (callback) ->

        testPackage.compile (err, source, sourceMap) ->

          throw err if err

          if testPath = output.test

            fs.mkdir path.dirname(testPath), ->

              fs.writeFile testPath, source, (err) ->

                throw err if err

                console.log "Compiled #{testPath}"

      vendor = (callback) ->

        if _.isEmpty(vendorDependencies) or ! output.vendor
          callback()
        else

          fs.mkdir output.vendor, ->

            async.forEach vendorDependencies, (source, _callback) ->

              name = path.basename source

              destination = [output.vendor, name].join '/'

              inputStream = fs.createReadStream source
              outputStream = fs.createWriteStream destination

              util.pump inputStream, outputStream, (err) ->
                throw err if err
                console.log "copied #{source} to #{destination}"
                _callback()

            , (err) ->
              throw err if err
              callback?()

      copyImages = (callback) ->

        if _.isEmpty(images) or ! output.images
          callback()
        else

          fs.mkdir output.images, ->

            async.forEach images, (source, _callback) ->

              destination = output.images

              wrench.copyDirSyncRecursive source, destination, { preserve: true }

              console.log "copied #{source} to #{destination}"

              _callback()

            , (err) ->
              throw err if err
              callback?()

      all = (callback) ->
        async.parallel [
          vendor
          copyImages
          buildStitch
        ], callback

      test = (callback) ->
        buildTest callback

      callback
        stitch: buildStitch
        vendor: vendor
        all: all
        test: test

  load: (root, options) ->

    tasks:
      stitch: (callback) =>
        @loadBuilders root, options, (builders) ->
          builders.stitch callback
      vendor: (callback) =>
        @loadBuilders root, options, (builders) ->
          builders.vendor callback
      all: (callback) =>
        @loadBuilders root, options, (builders) ->
          builders.all callback
      test: (callback) =>
        @loadBuilders root, options, (builders) ->
          builders.test callback
