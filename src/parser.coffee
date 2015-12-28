# The parser is currently a finite state machine that transitions between the
# states below.

START = 0  # Waiting for the next operation.
COMMAND = 1  # Parsing a command's arguments.
KV_KEY = 2  # Parsing a key-value's key.
KV_VALUE = 3  # Parsing a key-value's value.
DONE = 4  # Received the end-of-stream token.
CLOSED = 5  # Received close call.

# Assembles macro tokens into operations.
class Parser
  # Creates a new parser.
  constructor: ->
    @_ops = []
    @_lastError = null
    @_state = START
    @_op = null

  # Returns the last error encountered by this lexer.
  #
  # @return {String?} the last error encountered by this lexer
  lastError: ->
    @_lastError

  # Returns the codegen operations assembled by this lexer.
  ops: ->
    @_ops

  # Returns the lexer's current state.
  #
  # This method is most intended for testing and debugging.
  #
  # @return {String} the lexer's state
  state: ->
    switch @_state
      when START
        'start'
      when COMMAND
        'command'
      when KV_KEY
        'kv_key'
      when KV_VALUE
        'kv_value'
      when DONE
        'done'
      when CLOSED
        'closed'
      else
        '(unknown)'

  # Consumes one token.
  #
  # @param {String} token a lexed token
  # @return {Boolean} true if parsing was successful, false if an error
  #   occurred
  consume: (token) ->
    # Commands end when the current line ends.
    if @_state is COMMAND and (token.type is 'eos' or
        @_op.opcode.lineNumber isnt token.lineNumber)
      @_state = START
      @_ops.push @_op
      @_op = null

    if @_state is START
      switch token.type
        when 'label'
          @_ops.push op: 'def-label', label: token
        when 'opcode'
          @_state = COMMAND
          @_op = { op: 'command', opcode: token, args: [] }
        when 'keyword'
          if token.value is 'flag' or token.value is 'let'
            @_op = { op: token.value, name: null, value: null }
            @_state = KV_KEY
        when 'eos'
          @_state = DONE
        else
          @_lastError = "Line #{token.lineNumber}: unexpected #{token.type} " +
              "token #{token.value}"
          return false
    else if @_state is COMMAND
      if token.type is 'opcode' or token.type is 'keyword'
        @_lastError =  "Line #{token.lineNumber}: cannot have #{token.type} " +
            "#{token.value} as an argument for #{@_op.opcode.value}"
        @_state = START
        @_ops.push @_op
        @_op = null
        return false
      @_op.args.push token
    else if @_state is KV_KEY
      if token.type is 'eos'
        @_lastError = "Line #{token.lineNumber}: missing name after " +
            @_op.op
        @_state = DONE
        @_op = null
        return false

      @_op.name = token
      @_state = KV_VALUE
    else if @_state is KV_VALUE
      if token.type is 'eos'
        @_lastError = "Line #{token.lineNumber}: missing value after " +
            "#{@_op.op} #{@_op.name.value}"
        @_state = DONE
        @_op = null
        return false

      @_op.value = token
      @_state = START
      @_ops.push @_op
      @_op = null
    else if @_state is DONE
      @_lastError = "Line #{token.lineNumber}: more data received after " +
          "end-of-stream token"
      return false
    else if @_state is CLOSED
      throw new Error("Parser already closed")

    return true

  # Notifies the parser that no further {Parser#consume} calls will occur.
  close: ->
    unless @_state is DONE
      throw new Error(
          'Parsing was terminated before end-of-stream token was consumed')
    @_state = CLOSED
    @


module.exports = Parser
