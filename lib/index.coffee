stitch = require 'stitch'
fs = require 'fs'
path = require 'path'
util = require 'util'
async = require 'async'
wrench = require 'wrench'
jade = require 'jade'
_ = require 'underscore'
md = require('node-markdown').Markdown

merge = require './utils/merge'

Lexer = require('coffee-script/lib/coffee-script/lexer').Lexer

lexer = new Lexer()

handleQuotes = (string) ->
  # Might as well use CoffeeScript's lexer to handle the quotes in the html
  lexer.makeString string, "'", true

module.exports =

  loadBuilders: (root, options, callback) ->

    merge.mergeOptions root, options, (merged) ->

      { identifier, output, paths, testPaths, dependencies, vendorDependencies, testDependencies, images } = merged

      paths.reverse()
      testPaths.reverse()

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

        fs.mkdir path.dirname(output.app), ->

          pkg.compile (err, source) ->

            throw err if err

            fs.writeFile output.app, source, (err) ->

              throw err if err

              console.log "Compiled #{output.app}"

              callback?()

        if testPath = output.test

          fs.mkdir path.dirname(testPath), ->

            testPackage.compile (err, source) ->

              throw err if err

              fs.writeFile testPath, source, (err) ->

                throw err if err

                console.log "Compiled #{testPath}"

      vendor = (callback) ->

        if _.isEmpty vendorDependencies
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

        if _.isEmpty images
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

      callback
        stitch: buildStitch
        vendor: vendor
        all: all

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
