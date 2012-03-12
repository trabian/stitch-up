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

    config =
      json: true
      long: true

    npm.load config, (err) ->

      throw err if err

      npm.commands.list [], true, (err, out) ->

        deps = flatten out

        for package in deps

          if stitch = package.stitch

            for field in ['paths', 'dependencies', 'vendorDependencies', 'images']
              if array = stitch[field]
                array = [array] unless _.isArray array
                for item in array
                  jointOptions[field].push [package.path, item].join '/'

        callback jointOptions

flatten = (root, current, queue, seen) ->

  current or= root
  queue or= []
  seen or= [root]

  deps = current.dependencies or= {}

  for name, dep of deps

    return if typeof dep isnt "object"

    unless seen.indexOf(dep) is -1
      dep = deps[d] = Object.create(dep)
      dep.dependencies = {}

    queue.push dep
    seen.push dep

  unless queue.length
    return _.filter seen, (node) -> node.stitch
  #return root unless queue.length

  return flatten root, queue.shift(), queue, seen
