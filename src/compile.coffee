Environment = require './environment.coffee'
Macro = require './macro.coffee'

# Compiles a macro.
#
# @param {String} source the macro's source code
# @return {Macro} the compiled macro
compile = (source) ->
  environment = new Environment
  macro = new Macro environment
  unless macro._compile source
    throw new Error(macro.lastError())
  macro


module.exports = compile
