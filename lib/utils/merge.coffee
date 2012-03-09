_ = require 'underscore'

moduleNames = (options) ->

  keys = _.keys collection for collection in _.compact [options.dependencies, options.devDependencies]

  _.union _.flatten keys

module.exports =

  mergeOptions: (root, options) ->

    defaults =
      paths: []
      dependencies: []
      vendorDependencies: []
      images: []

    jointOptions = _.extend defaults, options.stitch

    for name in moduleNames(options)

      modulePath = "node_modules/#{name}"

      package = require "#{root}/#{modulePath}/package"

      if stitch = package.stitch

        for field in ['paths', 'dependencies', 'vendorDependencies', 'images']
          if array = stitch[field]
            array = [array] unless _.isArray array
            for item in array
              jointOptions[field].push [modulePath, item].join '/'

    jointOptions
