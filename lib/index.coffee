stitch = require 'stitch'
fs = require 'fs'
path = require 'path'
util = require 'util'
async = require 'async'
_ = require 'underscore'

merge = require './utils/merge'

module.exports =

  load: (root, options) ->

    { identifier, output, paths, dependencies, vendorDependencies } = merge.mergeOptions root, options

    package = stitch.createPackage
      paths: paths
      dependencies: dependencies
      identifier: identifier

    stitch = (callback) ->

      fs.mkdir path.dirname(output.app), ->

        package.compile (err, source) ->

          throw err if err

          fs.writeFile output.app, source, (err) ->

            throw err if err

            console.log "Compiled #{output.app}"

            callback?()

    vendor = (callback) ->

      console.log 'vendor'

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

    all = (callback) ->
      console.log 'all?'
      vendor -> stitch callback

    tasks: { stitch, vendor, all }
