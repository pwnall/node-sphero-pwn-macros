Environment = SpheroPwnMacros.Environment
Lexer = SpheroPwnMacros.Lexer
Macro = SpheroPwnMacros.Macro
Token = SpheroPwnMacros.Token

describe 'Macro', ->
  describe '#constructor', ->
    it 'creates an empty macro', ->
      env = new Environment
      macro = new Macro env
      expect(macro.environment()).to.equal env
      expect(macro.lastError()).to.equal null
      expect(macro.bytes).to.deep.equal [0x00]
      expect(macro.labels).to.deep.equal {}
      expect(macro._endsWithPcd).to.equal false

  describe '#addCommand', ->
    beforeEach ->
      @env = new Environment
      @macro = new Macro @env

    it 'adds end correctly', ->
      opcode = new Token 'opcode', 'end', 42
      args = []
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects invalid opcode', ->
      opcode = new Token 'opcode', 'nosuchop', 42
      args = []
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: invalid command opcode nosuchop')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects extra arguments to end', ->
      opcode = new Token 'opcode', 'end', 42
      args = [new Token('number', '2', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: end takes 0 arguments, got 1 arguments')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]

    it 'adds stabilization with value correctly', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('number', '2', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x03, 0x02, 0x00]
      expect(@macro._endsWithPcd).to.equal true

    it 'adds stabilization with builtin correctly', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('builtin', ':reset_on', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x03, 0x01, 0x00]
      expect(@macro._endsWithPcd).to.equal true

    it 'adds stabilization with variable correctly', ->
      name = new Token 'var', '$stabilization', 40
      value = new Token 'builtin', ':reset_on', 40
      success = @env.setVariable name, value
      expect(success).to.equal true

      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('var', '$stabilization', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x03, 0x01, 0x00]
      expect(@macro._endsWithPcd).to.equal true

    it 'rejects undefined variable name', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('var', '$stabilization', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: undefined variable $stabilization')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects label argument to stabilization', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('label', '%home', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag does not accept type label')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects invalid builtin argument to stabilization', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('builtin', ':invalid', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag does not accept value :invalid')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects underflow value argument to stabilization', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('number', '-1', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag value -1 below minimum 0')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects overflow value argument to stabilization', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('number', '16', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag value 16 above maximum 2')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects invalid builtin via variable argument to stabilization', ->
      name = new Token 'var', '$stabilization', 40
      value = new Token 'builtin', ':invalid', 40
      success = @env.setVariable name, value
      expect(success).to.equal true

      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('var', '$stabilization', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag does not accept value :invalid')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects underflow value via variable argument to stabilization', ->
      name = new Token 'var', '$stabilization', 40
      value = new Token 'number', -1, 40
      success = @env.setVariable name, value
      expect(success).to.equal true

      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('var', '$stabilization', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag value -1 below minimum 0')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects overflow value via variable argument to stabilization', ->
      name = new Token 'var', '$stabilization', 40
      value = new Token 'number', '16', 40
      success = @env.setVariable name, value
      expect(success).to.equal true

      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('var', '$stabilization', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: stabilization flag value 16 above maximum 2')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds roll with values correctly', ->
      opcode = new Token 'opcode', 'roll', 42
      args = [new Token('number', '63', 42 ), new Token('number', '300', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x05, 0x3F, 0x01, 0x2C, 0x00]
      expect(@macro._endsWithPcd).to.equal true

    it 'rejects builtin argument to roll', ->
      opcode = new Token 'opcode', 'roll', 42
      args = [new Token('number', '63', 42),
              new Token('builtin', ':north', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: roll heading does not accept builtins')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects builtin argument via variable to roll', ->
      name = new Token 'var', '$roll', 40
      value = new Token 'builtin', ':north', 40
      success = @env.setVariable name, value
      expect(success).to.equal true

      opcode = new Token 'opcode', 'roll', 42
      args = [new Token('number', '63', 42),
              new Token('var', '$roll', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: roll heading does not accept builtins')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds delay with value correctly', ->
      opcode = new Token 'opcode', 'delay', 42
      args = [new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(@macro.bytes).to.deep.equal [0x00, 0x0B, 0x04, 0xB0]
      expect(@macro._endsWithPcd).to.equal false

    it 'folds short delay into stabilization PCD', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('number', '2', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      opcode = new Token 'opcode', 'delay', 43
      args = [new Token('number', '15', 43)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(@macro.bytes).to.deep.equal [0x00, 0x03, 0x02, 0x0F]
      expect(@macro._endsWithPcd).to.equal false

    it 'expresses long delay as separate command', ->
      opcode = new Token 'opcode', 'stabilization', 42
      args = [new Token('number', '2', 42)]
      success = @macro.addCommand opcode, args
      expect(success).to.equal true
      opcode = new Token 'opcode', 'delay', 43
      args = [new Token('number', '256', 43)]
      success = @macro.addCommand opcode, args
      expect(success).to.equal true
      expect(@macro.lastError()).to.equal null
      expect(@macro.bytes).to.deep.equal(
          [0x00, 0x03, 0x02, 0x00, 0x0B, 0x01, 0x00])
      expect(@macro._endsWithPcd).to.equal false

    it 'adds sysspeed with register 1 correctly', ->
      opcode = new Token 'opcode', 'sysspeed', 42
      args = [new Token('number', '1', 42), new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x0F, 0x04, 0xB0]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds sysspeed with register 2 correctly', ->
      opcode = new Token 'opcode', 'sysspeed', 42
      args = [new Token('number', '2', 42), new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x10, 0x04, 0xB0]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds sysspeed with builtin :spd2 correctly', ->
      opcode = new Token 'opcode', 'sysspeed', 42
      args = [new Token('builtin', ':spd2', 42),
              new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x10, 0x04, 0xB0]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects sysspeed with invalid register correctly', ->
      opcode = new Token 'opcode', 'sysspeed', 42
      args = [new Token('number', '5', 42), new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: sysspeed register does not accept value 5')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'rejects sysspeed with invalid builtin correctly', ->
      opcode = new Token 'opcode', 'sysspeed', 42
      args = [new Token('builtin', ':spd5', 42),
              new Token('number', '1200', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal(
          'Line 42: sysspeed register does not accept value :spd5')
      expect(@macro.bytes).to.deep.equal [0x00]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds timedrotate with positive angularSpeed correctly', ->
      opcode = new Token 'opcode', 'timedrotate', 42
      args = [new Token('number', '720', 42), new Token('number', '4000', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(@macro.bytes).to.deep.equal [0x00, 0x1A, 0x02, 0xD0, 0x0F, 0xA0]
      expect(@macro._endsWithPcd).to.equal false

    it 'adds timedrotate with negative angularSpeed correctly', ->
      opcode = new Token 'opcode', 'timedrotate', 42
      args = [new Token('number', '-720', 42), new Token('number', '5000', 42)]
      success = @macro.addCommand opcode, args
      expect(@macro.lastError()).to.equal null
      expect(@macro.bytes).to.deep.equal [0x00, 0x1A, 0xFD, 0x30, 0x13, 0x88]
      expect(@macro._endsWithPcd).to.equal false

  describe '#consume', ->
    beforeEach ->
      @env = new Environment
      @macro = new Macro @env

    it 'processes a command op correctly', ->
      op =
        op: 'command'
        opcode: new Token('opcode', 'end', 42)
        args: []
      success = @macro.consume op
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x00, 0x00]

    it 'reports an error in a command op correctly', ->
      op =
        op: 'command'
        opcode: new Token('opcode', 'nosuchop', 42)
        args: []
      success = @macro.consume op
      expect(@macro.lastError()).to.equal(
          'Line 42: invalid command opcode nosuchop')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]

    it 'processes a flag op correctly', ->
      op =
        op: 'flag'
        name: new Token('var', '$exclusiveDrive', 42)
        value: new Token('builtin', ':on', 42)
      success = @macro.consume op
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal [0x02]

    it 'reports an error in a flag op correctly', ->
      op =
        op: 'flag'
        name: new Token('var', '$noSuchFlag', 42)
        value: new Token('builtin', ':on', 42)
      success = @macro.consume op
      expect(@macro.lastError()).to.equal(
          'Line 42: unknown flag name $noSuchFlag')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]

    it 'processes a let op correctly', ->
      value = new Token 'number', 1, 42
      op =
        op: 'let'
        name: new Token('var', '$red', 42)
        value: value
      success = @macro.consume op
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.getVariable('$red')).to.equal value

    it 'reports an error in a let op correctly', ->
      op =
        op: 'let'
        name: new Token('var', '$red', 42)
        value: new Token('var', '$green', 42)
      success = @macro.consume op
      expect(@macro.lastError()).to.equal(
          'Line 42: undefined variable $green')
      expect(@macro.bytes).to.deep.equal [0x00]

  describe '._compile', ->
    beforeEach ->
      @env = new Environment
      @macro = new Macro @env

    it 'builds a correct macro', ->
      source = '''
      flag $markerOnEnd :on
      let $stabilization :on
      stabilization $stabilization
      delay 1200
      end
      '''
      success = @macro._compile source
      expect(@macro.lastError()).to.equal null
      expect(success).to.equal true
      expect(@macro.bytes).to.deep.equal(
        [0x10, 0x03, 0x02, 0x00, 0x0B, 0x04, 0xB0, 0x00])

    it 'reports lexing errors correctly', ->
      source = '''
      stabilization :on
      delay 1200
      end ^derp
      '''
      success = @macro._compile source
      expect(@macro.lastError()).to.equal(
          'Line 3: invalid token starting at ^derp')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]

    it 'reports parsing errors correctly', ->
      source = '''
      stabilization :on
      delay 1200
      end delay 1200
      '''
      success = @macro._compile source
      expect(@macro.lastError()).to.equal(
          'Line 3: cannot have opcode delay as an argument for end')
      expect(success).to.equal false
      expect(@macro.bytes).to.deep.equal [0x00]

    it 'reports codegen errors correctly', ->
      source = '''
      stabilization :on
      delay :none
      end
      '''
      success = @macro._compile source
      expect(@macro.lastError()).to.equal(
          'Line 2: delay time does not accept builtins')
      expect(success).to.equal false
