Keywords = SpheroPwnMacros.Keywords

describe 'Keywords', ->
  it 'is an object', ->
    expect(Keywords).to.be.an 'object'

  it 'contains flag',  ->
    expect(Keywords).to.have.property 'flag'
