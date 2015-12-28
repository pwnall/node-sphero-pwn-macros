Keywords = require './keywords.coffee'
Token = require './token.coffee'

# Breaks down a macro's source code into tokens.
class Lexer
  # Creates a new lexer.
  #
  # @param {Object} options the options below
  # @option options {Number} lineNumber the number of the first line fed to the
  #   lexer; the default value is 1
  constructor: (options) ->
    @_tokens = []
    @_lastError = null
    if options and  'lineNumber' of options
      @_lineNumber = options.lineNumber
    else
      @_lineNumber = 1

  # Returns the line number assigned to the next lexed line.
  #
  # @return {Number} the line number assigned to the next lexed line
  lineNumber: ->
    @_lineNumber

  # Returns the last error encountered by this lexer.
  #
  # @return {String?} the last error encountered by this lexer
  lastError: ->
    @_lastError

  # Returns the tokens discovered by this lexer.
  #
  # @return {Array<Token>} the tokens discovered by this lexer
  tokens: ->
    @_tokens

  # Consumes a source code fragment.
  #
  # @param {String} source the macro's source code
  # @return {Boolean} true if the code was lexed successfully, false if an
  #   error occurred
  consume: (source) ->
    if source.length is 0  # Recursion base case: do nothing on empty string.
      return true

    type = null
    if match = /^\n/.exec(source)  # Newline
      @_lineNumber += 1
      type = ''
    else if match = /^#.*(\n|$)/.exec(source)  # Comment
      @_lineNumber += 1 if match[0].endsWith("\n")
      type = ''
    else if match =/^[ \t]+/.exec(source)  # Whitespace
      type = ''
    else if match = /^,/.exec(source)  # Separator
      type = ''
    else if match = /^%\w+/.exec(source)  # Label
      type = 'label'
    else if match = /^:\w+/.exec(source)  # Built-in constant.
      type = 'builtin'
    else if match = /^\$\w+/.exec(source)  # Variable.
      type = 'var'
    else if match = /^-?\d+/.exec(source)  # Number
      type = 'number'
    else if match = /^\w+/.exec(source)  # Opcode
      if match[0] of Keywords
        type = 'keyword'
      else
        type = 'opcode'

    if type is null
      match = /^\S*/.exec source
      start = match[0]
      @_lastError = "Line #{@_lineNumber}: invalid token starting at #{start}"
      return false

    consumedString = match[0]
    if type isnt ''
      token = new Token type, consumedString, @_lineNumber
      @_tokens.push token

    # NOTE: This relies on ES6 tail call optimization to not overflow the
    #       JavaScript call stack.
    @consume source.substring(consumedString.length)

  # Notifies the lexer that no further {Lexer#consume} calls will occur.
  #
  # @return {Boolean} true if the code was lexed successfully, false if an
  #   error occurred
  close: ->
    @_tokens.push new Token('eos', null, @_lineNumber)
    true


module.exports = Lexer
