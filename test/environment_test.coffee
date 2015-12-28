Environment = SpheroPwnMacros.Environment
Token = SpheroPwnMacros.Token

describe 'Environment', ->
  describe '#getVariable', ->
    beforeEach ->
      @env = new Environment
      @name = new Token 'var', '$red', 42
      @value = new Token 'number', '255', 42
      @env.setVariable @name, @value

    it 'returns a value token for existing variables', ->
      expect(@env.getVariable('$red')).to.equal @value
      expect(@env.lastError()).to.equal null

    it 'returns null for undefined variables', ->
      expect(@env.getVariable('$green')).to.equal null
      expect(@env.lastError()).to.equal null

  describe '#getVariableByToken', ->
    beforeEach ->
      @env = new Environment
      @name = new Token 'var', '$red', 42
      @value = new Token 'number', '255', 42
      @env.setVariable @name, @value

    it 'returns a value token for existing variables', ->
      expect(@env.getVariableByToken(@name)).to.equal @value
      expect(@env.lastError()).to.equal null

    it 'returns null for undefined variables', ->
      name2 = new Token 'var', '$green', 44
      expect(@env.getVariableByToken(name2)).to.equal null
      expect(@env.lastError()).to.equal 'Line 44: undefined variable $green'

  describe '#setVariable', ->
    beforeEach ->
      @env = new Environment

    it 'processes a correct builtin assignment', ->
      name = new Token 'var', '$red', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setVariable name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.getVariable('$red')).to.equal value

    it 'processes a correct number assignment', ->
      name = new Token 'var', '$red', 42
      value = new Token 'number', '255', 42
      success = @env.setVariable name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.getVariable('$red')).to.equal value

    it 'processes a correct variable assignment', ->
      name = new Token 'var', '$red', 42
      value = new Token 'number', '255', 42
      @env.setVariable name, value
      expect(@env.getVariable('$red')).to.equal value

      name2 = new Token 'var', '$green', 42
      value2 = new Token 'var', '$red', 42
      success = @env.setVariable name2, value2
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.getVariable('$green')).to.equal value

    it 'rejects an assignment to a non-variable name', ->
      name = new Token 'number', '42', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setVariable name, value
      expect(@env.lastError()).to.equal(
          'Line 42: invalid variable name type number')
      expect(success).to.equal false
      expect(@env.getVariable(42)).to.equal null
      expect(@env.getVariable('42')).to.equal null

    it 'rejects an undefined variable assignment', ->
      name = new Token 'var', '$green', 42
      value = new Token 'var', '$red', 42
      success = @env.setVariable name, value
      expect(@env.lastError()).to.equal 'Line 42: undefined variable $red'
      expect(success).to.equal false
      expect(@env.getVariable('$green')).to.equal null
      expect(@env.getVariable('$red')).to.equal null

    it 'rejects a keyword assignment', ->
      name = new Token 'var', '$red', 42
      value = new Token 'keyword', 'var', 42
      success = @env.setVariable name, value
      expect(@env.lastError()).to.equal(
          'Line 42: invalid variable value type keyword')
      expect(success).to.equal false
      expect(@env.getVariable('$red')).to.equal null

  describe '#setFlag', ->
    beforeEach ->
      @env = new Environment

    it 'processes a correct :on assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x02

    it 'processes a correct :off assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'builtin', ':off', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x00

    it 'processes a correct 1 assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'number', 1, 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x02

    it 'processes a correct 0 assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'number', 0, 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x00

    it 'processes two correct :on assignments', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setFlag name, value
      expect(success).to.equal true

      name = new Token 'var', '$stopOnDisconnect', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal null
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x06

    it 'rejects an assignment to a non-variable flag name', ->
      name = new Token 'number', '42', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal(
          'Line 42: invalid flag name type number')
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00

    it 'rejects an assignment to an invalid flag name', ->
      name = new Token 'var', '$noSuchFlag', 42
      value = new Token 'builtin', ':on', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal(
          'Line 42: unknown flag name $noSuchFlag')
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00

    it 'rejects a label assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'label', '%home', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal(
          'Line 42: invalid flag value type label')
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00

    it 'rejects an invalid builtin assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'builtin', ':invalid', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal(
          'Line 42: invalid flag value :invalid')
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00

    it 'rejects an invalid value assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'number', '2', 42
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal 'Line 42: invalid flag value 2'
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00

    it 'rejects a double assignment', ->
      name = new Token 'var', '$exclusiveDrive', 42
      value = new Token 'builtin', ':off', 42
      success = @env.setFlag name, value
      expect(success).to.equal true
      expect(@env.flagByte()).to.equal 0x00

      name = new Token 'var', '$exclusiveDrive', 44
      value = new Token 'builtin', ':on', 44
      success = @env.setFlag name, value
      expect(@env.lastError()).to.equal(
          'Line 44: flag $exclusiveDrive already set to :off on line 42')
      expect(success).to.equal false
      expect(@env.flagByte()).to.equal 0x00
