stitch = require 'stitch'
fs = require 'fs'
path = require 'path'
util = require 'util'

merge = require './utils/merge'

module.exports =

  load: (root, options) ->

    { output, paths, dependencies, vendorDependencies } = merge.mergeOptions root, options

    package = stitch.createPackage

      paths: paths

      dependencies: dependencies

    stitch = ->

      fs.mkdir path.dirname(output.app), ->

        package.compile (err, source) ->

          throw err if err

          fs.writeFile output.app, source, (err) ->

            throw err if err

            console.log "Compiled #{output.app}"

    vendor = ->

      fs.mkdir output.vendor, ->

        for source in vendorDependencies

          do (source) ->

            name = path.basename source

            destination = [output.vendor, name].join '/'

            inputStream = fs.createReadStream source
            outputStream = fs.createWriteStream destination

            util.pump inputStream, outputStream, (err) ->
              throw err if err
              console.log "copied #{source} to #{destination}"

    all = ->
      do task for task in [stitch, vendor]

    { stitch, vendor, all }
