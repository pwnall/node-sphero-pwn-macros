Token = SpheroPwnMacros.Token

describe 'Token', ->
  it 'parses a positive number', ->
    token = new Token 'number', '193', 42
    expect(token.type).to.equal 'number'
    expect(token.value).to.equal 193
    expect(token.lineNumber).to.equal 42

  it 'parses a negative number', ->
    token = new Token 'number', '-193', 42
    expect(token.type).to.equal 'number'
    expect(token.value).to.equal -193
    expect(token.lineNumber).to.equal 42

  it 'parses an opcode', ->
    token = new Token 'opcode', 'end', 42
    expect(token.type).to.equal 'opcode'
    expect(token.value).to.equal 'end'
    expect(token.lineNumber).to.equal 42
