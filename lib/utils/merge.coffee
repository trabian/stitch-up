npm = require 'npm'
_ = require 'underscore'

moduleNames = (options) ->

  keys = _.keys collection for collection in _.compact [options.dependencies, options.devDependencies]

  _.union _.flatten keys

findPackagePath = (deps, name, callback) ->

  for dependency in deps
    for _name, childDependency of dependency.dependencies
      if name is _name
        return childDependency.path

module.exports =

  mergeOptions: (root, options, callback) ->

    jointOptions =
      paths: []
      testPaths: []
      dependencies: []
      testDependencies: []
      vendorDependencies: []
      images: []
      output: options.stitch.output
      identifier: options.stitch.identifier

    config =
      json: true
      long: true

    npm.load config, (err) ->

      throw err if err

      npm.commands.list [], true, (err, out) ->

        deps = flatten out

        for pkg in deps

          if stitch = pkg.stitch

            for field in ['paths', 'testPaths', 'dependencies', 'testDependencies', 'vendorDependencies', 'images']
              if array = stitch[field]
                array = [array] unless _.isArray array
                for item in array

                  if match = item.match '(.*):(.*)'

                    [full, dependentPackage, dependentPath] = match

                    path = [findPackagePath(deps, dependentPackage), dependentPath].join '/'

                  else
                    path = [pkg.path, item].join '/'

                  jointOptions[field].push path

              jointOptions[field] = _.uniq jointOptions[field], false, (path) ->

                name = _.last path.split '/'

                # Remove duplicate .js files
                if name.match /\.js$/
                  name
                else
                  path

        callback jointOptions

flatten = (root, current, queue, seen) ->

  current or= root
  queue or= []
  seen or= [root]

  deps = current.dependencies or= {}

  for name, dep of deps

    if typeof dep is 'object'

      unless seen.indexOf(dep) is -1
        dep = deps[d] = Object.create(dep)
        dep.dependencies = {}

      queue.push dep
      seen.push dep

  unless queue.length
    return _.filter seen, (node) -> node.stitch
  #return root unless queue.length

  return flatten root, queue.shift(), queue, seen

