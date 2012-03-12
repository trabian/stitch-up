npm = require 'npm'
_ = require 'underscore'

moduleNames = (options) ->

  keys = _.keys collection for collection in _.compact [options.dependencies, options.devDependencies]

  _.union _.flatten keys

module.exports =

  mergeOptions: (root, options, callback) ->

    defaults =
      paths: []
      dependencies: []
      vendorDependencies: []
      images: []

    jointOptions = _.extend defaults, options.stitch

    npm.load {}, (err) ->

      throw err if err

      npm.commands.list [], true, (err, out) ->

        for name, package of out.dependencies

          if stitch = package.stitch

            for field in ['paths', 'dependencies', 'vendorDependencies', 'images']
              if array = stitch[field]
                array = [array] unless _.isArray array
                for item in array
                  jointOptions[field].push [package.path, item].join '/'

        callback jointOptions
