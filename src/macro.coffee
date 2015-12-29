Commands = require './commands.coffee'
Lexer = require './lexer.coffee'
Parser = require './parser.coffee'

# Compiles macros for Sphero robots.
class Macro
  # @return {Object<String, Number>} maps label names to command numbers
  labels: null

  # @return {Array<Number>} the bytes that make up the compiled macro
  bytes: null

  # Creates an empty macro.
  #
  # @param {Environment} environment the macro's evaluation environment
  constructor: (environment) ->
    @_env = environment
    @labels = {}
    @bytes = [0x00]
    @_lastCommand = null
    @_lastCommandOffset = null
    @_lastError = null
    @_opOffsets = []

  # Returns the macro's environment.
  #
  # @return {Environment} the environment used to look up variable names inside
  #   the macro
  environment: ->
    @_env

  # Returns the last error encountered in this macro's construction.
  #
  # @return {String?} the last error encountered by this lexer
  lastError: ->
    @_lastError

  # Extends the macro with a command.
  #
  # @param {Token} opcode the lexed token containing the command's opcode
  # @param {Array<Token>} args the lexed token containing the command's
  #   arguments
  # @return {Boolean} true if the command was added successfully, false
  #   otherwise
  addCommand: (opcode, args) ->
    bytes = null  # The bytes to be added to the stream.
    hasPcd = false  # True if the command ends in a PCD byte.

    errorStart = "Line #{opcode.lineNumber}:"

    name = opcode.value
    commandData = Commands[name]
    unless commandData
      @_lastError = "#{errorStart} invalid command opcode #{opcode.value}"
      return false

    errorStart = "#{errorStart} #{name}"

    if args.length isnt commandData.args.length
      @_lastError = "#{errorStart} takes #{commandData.args.length} " +
          "arguments, got #{args.length} arguments"
      return false

    bytes = [commandData.byteCode]
    for commandArg, index in commandData.args
      argName = commandArg.name
      argToken = args[index]

      # NOTE: Variable substitution must be done before builtin evaluation.
      if argToken.type is 'var'
        argToken = @_env.getVariableByToken argToken
        if argToken is null
          @_lastError = @_env.lastError()
          return false

      switch argToken.type
        when 'number'
          value = argToken.value
        when 'builtin'
          if commandArg.builtins
            builtinName = argToken.value.substring 1
            if builtinName of commandArg.builtins
              value = commandArg.builtins[builtinName]
            else
              @_lastError = "#{errorStart} #{argName} does not accept value " +
                  argToken.value
              return false
          else
            @_lastError = "#{errorStart} #{argName} does not accept builtins"
            return false
        else
          @_lastError = "#{errorStart} #{argName} does not accept type " +
              argToken.type
          return false

      if value < commandArg.min
        @_lastError = "#{errorStart} #{argName} value #{value} below " +
            "minimum #{commandArg.min}"
        return false
      if value > commandArg.max
        @_lastError = "#{errorStart} #{argName} value #{value} above " +
            "maximum #{commandArg.max}"
        return false

      switch commandArg.type
        when 'uint8'
          bytes.push value
        when 'uint16'
          bytes.push value >> 8
          bytes.push value & 0xFF
        when 'sint16'
          value = 0x10000 + value if value < 0
          bytes.push value >> 8
          bytes.push value & 0xFF
        when 'bytecode'
          if value of commandArg.byteCodes
            bytes[0] = commandArg.byteCodes[value]
          else
            @_lastError = "#{errorStart} #{argName} does not accept value " +
                argToken.value
            return false
        else
          throw new Error("Unimplemented argument type #{commandArg.type}")

    if commandData.fusion.pcd
      bytes.push 0x00

    # We don't ask users to remember which commands have a PCD byte. Instead,
    # we automatically convert a PCD command followed by a delay command into
    # into one command with a non-zero PCD byte.
    if bytes[0] is 0x0B and @_lastCommand isnt null
      if @_lastCommand.fusion.pcd is true and bytes[1] is 0
        @bytes[@bytes.length - 1] = bytes[2]
        bytes = []
      else if @_lastCommand.fusion.pcd2 isnt null
        @bytes[@_lastCommandOffset] = @_lastCommand.fusion.pcd2.byteCode
        @bytes[@bytes.length - 1] = bytes[1]
        @bytes.push bytes[2]
        bytes = []

    # TODO(pwnall): roll+delay -> roll2 optimization

    @_lastCommand = commandData
    @_lastCommandOffset = @bytes.length
    unless bytes.length is 0
      @_opOffsets.push @bytes.length
      @bytes.push byte for byte in bytes

    true

  # Compiles a macro.
  #
  # @param {String} source the macro's source code
  # @return {Boolean} true if the compilation succeeded, false otherwise
  _compile: (source) ->
    lexer = new Lexer
    unless lexer.consume source
      @_lastError = lexer.lastError()
      return false
    lexer.close()

    parser = new Parser
    for token in lexer.tokens()
      unless parser.consume token
        @_lastError = parser.lastError()
        return false
    parser.close()

    for op in parser.ops()
      unless @consume op
        return false
    true

  # Applies a code generation operation produced by the macro parser.
  #
  # @return {Boolean} true if the code generation succeeded, false otherwise
  consume: (op) ->
    switch op.op
      when 'command'
        success = @addCommand op.opcode, op.args
      when 'flag'
        success = @_env.setFlag op.name, op.value
        if success
          @bytes[0] = @_env.flagByte()
        else
          @_lastError = @_env.lastError()
      when 'let'
        success = @_env.setVariable op.name, op.value
        unless success
          @_lastError = @_env.lastError()
    success


module.exports = Macro
