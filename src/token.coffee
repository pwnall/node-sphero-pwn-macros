# A lexed token from a macro.
class Token
  # @return {String} the token's type
  type: null

  # @return {Object} the token's semantic value
  value: null

  # @return {Number} the number of the source code line containing the token
  lineNumber: null

  # Creates a token from a type and a source code fragment.
  #
  # @param {String} type the token's type
  # @param {String} source the source code fragment
  # @param {Number} lineNumber the source code line where the token was lexed
  constructor: (type, source, lineNumber) ->
    @type = type
    @lineNumber = lineNumber
    if type is 'number'
      @value = parseInt source
    else
      @value = source


module.exports = Token
