# Table of commands used by the code generator.
#
# The format of this table is intimately tied to the implementation of
# {Macro#addCommand}.
MacroCommands =
  # End
  end: {
    byteCode: 0x00,
    args: [],
    fusion: { pcd: false, pcd2: null }
  }

  # Stream End
  endstream: {
    byteCode: 0x1B,
    args: [],
    fusion: { pcd: false, pcd2: null }
  }

  # Set SD1, SD2
  sysdelay: {
    byteCode: 0x01
    args: [{
      name: 'register'
      type: 'bytecode', min: 0, max: 0xFF
      builtins: { sd1: 1, sd2: 2 }
      byteCodes: { '1': 0x01, '2': 0x02 }
    }, {
      name: 'delay',
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Set Stabilization
  stabilization: {
    byteCode: 0x03
    args: [{
      name: 'flag'
      type: 'uint8', min: 0, max: 2
      builtins: { off: 0, reset_on: 1, on: 2 }
    }]
    fusion: { pcd: true, pcd2: null }
  }

  # Set Heading
  heading: {
    byteCode: 0x04
    args: [{
      name: 'heading'
      type: 'uint16', min: 0, max: 359
    }]
    fusion: { pcd: true, pcd2: null }
  }

  # Set Rotation Rate
  maxrotation: {
    byteCode: 0x13
    args: [{
      name: 'rate'
      type: 'uint8', min: 0, max: 0xFF
    }]
  }

  # Roll
  roll: {
    byteCode: 0x05
    args: [{
      name: 'speed'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'heading'
      type: 'uint16', min: 0, max: 359
    }]
    fusion:
      pcd: true
      pcd2: { byteCode: 0x1D }
  }

  # Set RGB LED
  rgb: {
    byteCode: 0x07
    args: [{
      name: 'red'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'green'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'blue'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: true, pcd2: null }
  }

  # Set Back LED
  backled: {
    byteCode: 0x09
    args: [{
      name: 'intensity'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: true, pcd2: null }
  }

  # Send Raw Motor Commands
  motor: {
    byteCode: 0x0A
    args: [{
      name: 'leftMode'
      type: 'uint8', min: 0, max: 4
      builtins: { off: 0, forward: 1, reverse: 2, brake: 3, ignore: 4 }
    }, {
      name: 'leftPower'
      type: 'uint8', min: 0, max: 255
    }, {
      name: 'rightMode'
      type: 'uint8', min: 0, max: 4
      builtins: { off: 0, forward: 1, reverse: 2, brake: 3, ignore: 4 }
    }, {
      name: 'rightPower'
      type: 'uint8', min: 0, max: 255
    }]
    fusion: { pcd: true, pcd2: null }
  }

  # Delay
  delay: {
    byteCode: 0x0B
    args: [{
      name: 'time'
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Goto
  goto: {
    byteCode: 0x0C
    args: [{
      name: 'macroId'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Gosub
  gosub: {
    byteCode: 0x0D
    args: [{
      name: 'macroId'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Sleep
  sleep: {
    byteCode: 0x0E
    args: [{
      name: 'time'
      type: 'uint16', min: 0, max: 0xFFFF
      builtins: { forever: 0, api: 0xFFFF }
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Set SPD1, SPD2
  sysspeed: {
    byteCode: 0x0F
    args: [{
      name: 'register'
      type: 'bytecode', min: 0, max: 0xFF
      builtins: { spd1: 1, spd2: 2 }
      byteCodes: { '1': 0x0F, '2': 0x10 }
    }, {
      name: 'speed'
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Fade to LED Over Time
  rgbfade: {
    byteCode: 0x14
    args: [{
      name: 'red'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'green'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'blue'
      type: 'uint8', min: 0, max: 0xFF
    }, {
      name: 'duration'
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Emit Marker
  marker: {
    byteCode: 0x15
    args: [{
      name: 'value'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Wait Until Stopped
  waitforstop: {
    byteCode: 0x19
    args: [{
      name: 'timeout',
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Rotate Over Time
  timedrotate: {
    byteCode: 0x1A
    args: [{
      name: 'angularSpeed'
      type: 'sint16', min: -0x3FFF, max: 0x3FFF
    }, {
      name: 'time'
      type: 'uint16', min: 0, max: 0xFFFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Loop Start
  repeat: {
    byteCode: 0x1E
    args: [{
      name: 'count',
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Loop End
  endrepeat: {
    byteCode: 0x1F
    args: []
    fusion: { pcd: false, pcd2: null }
  }

  # Goto
  oncollision: {
    byteCode: 0x0C
    args: [{
      name: 'macroId'
      type: 'uint8', min: 0, max: 0xFF
      builtins: { do_nothing: 0 }
    }]
    fusion: { pcd: false, pcd2: null }
  }

  # Set Speed
  speed: {
    byteCode: 0x25
    args: [{
      name: 'speed'
      type: 'uint8', min: 0, max: 0xFF
    }]
    fusion: { pcd: true, pcd2: null }
  }


module.exports = MacroCommands
