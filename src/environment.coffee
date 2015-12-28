Flags = require './flags.coffee'

# The evaluation environment for a macro.
class Environment
  # Creates an empty evaluation environment.
  constructor: ->
    @_flagValues = {}
    @_varValues = {}
    @_flagByte = 0x00
    @_lastError = null

  # Returns the last error encountered by this environment.
  #
  # @return {String?} the last error encountered by this lexer
  lastError: ->
    @_lastError

  # Resolves a variable.
  #
  # @param {String} name the variable name
  # @return {Token?} the lexed token containing the variable's value; null if
  #   the variable was not defined
  getVariable: (name) ->
    if name of @_varValues
      @_varValues[name]
    else
      null

  # Resolves a variable.
  #
  # If the variable is not resolved, {Environment#lastError} is set to an error
  # describing the situation.
  #
  # @param {String} name the variable name
  # @return {Token?} the lexed token containing the variable's value; null if
  #   the variable was not defined
  getVariableByToken: (nameToken) ->
    varValue = @getVariable nameToken.value
    if varValue is null
      @_lastError =
          "Line #{nameToken.lineNumber}: undefined variable #{nameToken.value}"
    varValue

  # Sets the value of a variable.
  #
  # @param {Token} name the lexed token containing the flag's name
  # @param {Token} value the lexed token containing the flag's value
  # @return {String?} if not null, it represents an error message
  setVariable: (name, value) ->
    if name.type isnt 'var'
      @_lastError =
          "Line #{name.lineNumber}: invalid variable name type #{name.type}"
      return false
    varName = name.value

    varValue = null
    switch value.type
      when 'number'
        varValue = value
      when 'builtin'
        varValue = value
      when 'var'
        varValue = @getVariableByToken value
        return false if varValue is null
      else
        @_lastError = "Line #{value.lineNumber}: invalid variable value " +
            "type #{value.type}"
        return false

    @_varValues[varName] = varValue
    true

  # Returns the byte that collects flag values.
  #
  # This is intended for testing and debugging.
  #
  # @return {Number} the byte containing flag values
  flagByte: ->
    @_flagByte

  # Sets the value of a flag.
  #
  # @param {Token} name the lexed token containing the flag's name
  # @param {Token} value the lexed token containing the flag's value
  # @return {String?} if not null, it represents an error message
  setFlag: (name, value) ->
    if name.type isnt 'var'
      @_lastError =
          "Line #{name.lineNumber}: invalid flag name type #{name.type}"
      return false

    flagName = name.value.substring 1
    unless flagMask = Flags[flagName]
      @_lastError =
          "Line #{name.lineNumber}: unknown flag name #{name.value}"
      return false

    flagValue = null
    switch value.type
      when 'builtin'
        if value.value is ':on'
          flagValue = true
        else if value.value is ':off'
          flagValue = false
      when 'number'
        if value.value is 1
          flagValue = true
        else if value.value is 0
          flagValue = false
      else
        @_lastError = "Line #{value.lineNumber}: invalid flag value type " +
            value.type
        return false

    if flagValue is null
      @_lastError = "Line #{value.lineNumber}: invalid flag value " +
          value.value
      return false

    if oldValue = @_flagValues[flagName]
      @_lastError = "Line #{value.lineNumber}: flag #{name.value} already " +
          "set to #{oldValue.value} on line #{oldValue.lineNumber}"
      return false
    @_flagValues[flagName] = value

    if flagValue is true
      @_flagByte |= flagMask

    true


module.exports = Environment
