describe 'compile', ->
  it 'builds a correct macro', ->
    source = '''
    flag $markerOnEnd :on
    let $stabilization :on
    stabilization :on
    delay 1200
    end
    '''
    macro = SpheroPwnMacros.compile source
    expect(macro.bytes).to.deep.equal(
      [0x10, 0x03, 0x02, 0x00, 0x0B, 0x04, 0xB0, 0x00])

  it 'reports errors', ->
    source = '''
    stabilization :on
    delay 1200
    end ^derp
    '''
    try
      SpheroPwnMacros.compile source
      expect(false).to.equal 'expected error not thrown'
    catch error
      expect(error).to.be.an.instanceOf Error
      expect(error.message).to.equal 'Line 3: invalid token starting at ^derp'
