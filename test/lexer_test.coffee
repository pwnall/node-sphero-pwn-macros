Lexer = SpheroPwnMacros.Lexer
Token = SpheroPwnMacros.Token

describe 'Lexer', ->
  describe '#constructor', ->
    it 'sets default lineNumber to 1 without options', ->
      lexer = new Lexer
      expect(lexer.lineNumber()).to.equal 1
      expect(lexer.tokens()).to.deep.equal []
      expect(lexer.lastError()).to.deep.equal null

    it 'sets default lineNumber to 1 with empty options', ->
      lexer = new Lexer {}
      expect(lexer.lineNumber()).to.equal 1
      expect(lexer.tokens()).to.deep.equal []
      expect(lexer.lastError()).to.deep.equal null

    it 'processes lineNumber option', ->
      lexer = new Lexer lineNumber: 42
      expect(lexer.lineNumber()).to.equal 42
      expect(lexer.tokens()).to.deep.equal []
      expect(lexer.lastError()).to.deep.equal null

  describe '#consume', ->
    beforeEach ->
      @lexer = new Lexer lineNumber: 42

    it 'stops on the empty string', ->
      success = @lexer.consume ''
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes whitespace', ->
      success = @lexer.consume "    \t \t \t     "
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a newline', ->
      success = @lexer.consume "\n"
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 43

    it 'lexes an opcode', ->
      success = @lexer.consume 'end'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('opcode', 'end', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a label', ->
      success = @lexer.consume '%home'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('label', '%home', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a built-in value', ->
      success = @lexer.consume ':on'
      expect(@lexer.lastError()).to.equal null
      expect(@lexer.tokens()).to.deep.equal [new Token('builtin', ':on', 42)]
      expect(success).to.equal true
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a variable', ->
      success = @lexer.consume '$red'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('var', '$red', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes the flag keyword', ->
      success = @lexer.consume 'flag'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('keyword', 'flag', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes the let keyword', ->
      success = @lexer.consume 'let'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('keyword', 'let', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a number', ->
      success = @lexer.consume '193'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('number', '193', 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a negative number', ->
      success = @lexer.consume '-193'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('number', -193, 42)]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a comment at the end of the source', ->
      success = @lexer.consume '# end all things'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a comment at the end of the line', ->
      success = @lexer.consume "# end all things\n"
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 43

    it 'barfs at unknown characters', ->
      success = @lexer.consume '^herp derp'
      expect(@lexer.lastError()).to.equal(
          'Line 42: invalid token starting at ^herp')
      expect(success).to.equal false
      expect(@lexer.tokens()).to.deep.equal []
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes a sequence of tokens', ->
      success = @lexer.consume '%home rgb 255, 128 0  # Orange'
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [
        new Token('label', '%home', 42),
        new Token('opcode', 'rgb', 42),
        new Token('number', 255, 42),
        new Token('number', 128, 42),
        new Token('number', 0, 42),
      ]
      expect(@lexer.lineNumber()).to.equal 42

    it 'lexes multiple lines', ->
      success = @lexer.consume "%home\n# Glow orange\nrgb 255, 128, 0\n"
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [
        new Token('label', '%home', 42),
        new Token('opcode', 'rgb', 44),
        new Token('number', '255', 44),
        new Token('number', '128', 44),
        new Token('number', '0', 44),
      ]
      expect(@lexer.lineNumber()).to.equal 45

  describe '#close', ->
    beforeEach ->
      @lexer = new Lexer lineNumber: 42

    it 'adds an end-of-stream token', ->
      success = @lexer.close()
      expect(@lexer.lastError()).to.equal null
      expect(success).to.equal true
      expect(@lexer.tokens()).to.deep.equal [new Token('eos', null, 42)]
      expect(@lexer.lineNumber()).to.equal 42
