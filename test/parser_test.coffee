Parser = SpheroPwnMacros.Parser
Token = SpheroPwnMacros.Token

describe 'Parser', ->
  describe '#constructor', ->
    it 'initializes the parser state correctly', ->
      parser = new Parser
      expect(parser.lastError()).to.equal null
      expect(parser.state()).to.equal 'start'
      expect(parser.ops()).to.deep.equal []

  describe '#close', ->
    beforeEach ->
      @parser = new Parser

    it 'throws an error if called before eos is consumed', ->
      try
        @parser.close()
        expect(false).to.equal '#close() did not throw'
      catch error
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.equal(
            'Parsing was terminated before end-of-stream token was consumed')
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'start'

    it 'closes the parser if eos is consumed', ->
      @parser.consume new Token('eos', null, 42)
      @parser.close()
      expect(@parser.state()).to.equal 'closed'
      expect(@parser.ops()).to.deep.equal []

  describe '#parse', ->
    beforeEach ->
      @parser = new Parser

    it 'parses end-of-stream', ->
      success = @parser.consume new Token('eos', null, 42)
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'rejects double end-of-stream', ->
      @parser.consume new Token('eos', null, 42)
      expect(@parser.state()).to.equal 'done'
      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal(
          'Line 43: more data received after end-of-stream token')
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'parses a label definition', ->
      label = new Token 'label', '%hello', 42
      success = @parser.consume label
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'def-label', label: label }]
      expect(@parser.state()).to.equal 'start'

    it 'parses a command followed by eos', ->
      opcode = new Token 'opcode', 'end', 42
      success = @parser.consume opcode
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'command'

      @parser.consume new Token('eos', null, 42)
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'command', opcode: opcode, args: [] }]
      expect(@parser.state()).to.equal 'done'

    it 'parses a command followed by another command', ->
      opcode = new Token 'opcode', 'end', 42
      success = @parser.consume opcode
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'command'

      @parser.consume new Token('opcode', 'endstream', 43)
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'command', opcode: opcode, args: [] }]
      expect(@parser.state()).to.equal 'command'

    it 'parses a command with arguments', ->
      opcode = new Token 'opcode', 'end', 42
      success = @parser.consume opcode
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'command'

      args = [
        new Token('number', 123, 42),
        new Token('var', '$red', 42),
        new Token('label', '%home', 42)
        new Token('builtin', '%home', 42)
      ]
      for arg in args
        success = @parser.consume arg
        expect(@parser.lastError()).to.equal null
        expect(success).to.equal true
        expect(@parser.ops()).to.deep.equal []
        expect(@parser.state()).to.equal 'command'

      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'command', opcode: opcode, args: args }]
      expect(@parser.state()).to.equal 'done'

    it 'rejects two commands on the same line', ->
      opcode = new Token 'opcode', 'end', 42
      @parser.consume opcode
      expect(@parser.state()).to.equal 'command'

      success = @parser.consume new Token('opcode', 'endstream', 42)
      expect(@parser.lastError()).to.equal(
          'Line 42: cannot have opcode endstream as an argument for end')
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal [
          { op: 'command', opcode: opcode, args: [] }]
      expect(@parser.state()).to.equal 'start'

    it 'rejects a command that includes a keyword', ->
      opcode = new Token 'opcode', 'end', 42
      @parser.consume opcode
      expect(@parser.state()).to.equal 'command'

      success = @parser.consume new Token('keyword', 'let', 42)
      expect(@parser.lastError()).to.equal(
          'Line 42: cannot have keyword let as an argument for end')
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal [
          { op: 'command', opcode: opcode, args: [] }]
      expect(@parser.state()).to.equal 'start'

    it 'parses a let assignment', ->
      keyword = new Token 'keyword', 'let', 42
      success = @parser.consume keyword
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'kv_key'

      name = new Token 'var', '$red', 42
      success = @parser.consume name
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'kv_value'

      value = new Token 'number', '255', 42
      success = @parser.consume value
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'let', name: name, value: value }]
      expect(@parser.state()).to.equal 'start'

    it 'rejects a let assignment without a name', ->
      @parser.consume new Token('keyword', 'let', 42)
      expect(@parser.state()).to.equal 'kv_key'

      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal 'Line 43: missing name after let'
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'rejects a let assignment without a value', ->
      @parser.consume new Token('keyword', 'let', 42)
      expect(@parser.state()).to.equal 'kv_key'

      @parser.consume new Token('var', '$red', 42)
      expect(@parser.state()).to.equal 'kv_value'

      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal(
          'Line 43: missing value after let $red')
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'parses a flag assignment', ->
      keyword = new Token 'keyword', 'flag', 42
      success = @parser.consume keyword
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'kv_key'

      name = new Token 'var', '$exclusiveDrive', 42
      success = @parser.consume name
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'kv_value'

      value = new Token 'builtin', ':on', 42
      success = @parser.consume value
      expect(@parser.lastError()).to.equal null
      expect(success).to.equal true
      expect(@parser.ops()).to.deep.equal [
          { op: 'flag', name: name, value: value }]
      expect(@parser.state()).to.equal 'start'

    it 'rejects a flag assignment without a name', ->
      @parser.consume new Token('keyword', 'flag', 42)
      expect(@parser.state()).to.equal 'kv_key'

      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal 'Line 43: missing name after flag'
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'rejects a flag assignment without a value', ->
      @parser.consume new Token('keyword', 'flag', 42)
      expect(@parser.state()).to.equal 'kv_key'

      @parser.consume new Token('var', '$exclusiveDrive', 42)
      expect(@parser.state()).to.equal 'kv_value'

      success = @parser.consume new Token('eos', null, 43)
      expect(@parser.lastError()).to.equal(
          'Line 43: missing value after flag $exclusiveDrive')
      expect(success).to.equal false
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'done'

    it 'throws an exception if called after #close', ->
      @parser.consume new Token('eos', null, 42)
      expect(@parser.state()).to.equal 'done'
      @parser.close()
      expect(@parser.state()).to.equal 'closed'

      try
        @parser.consume new Token('command', 'end', 43)
        expect(false).to.equal '#parse() did not throw'
      catch error
        expect(error).to.be.an.instanceOf Error
        expect(error.message).to.equal 'Parser already closed'
      expect(@parser.ops()).to.deep.equal []
      expect(@parser.state()).to.equal 'closed'
