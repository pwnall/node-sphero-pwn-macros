# Node.js Macro Compiler for Sphero Robots

[![Build Status](https://travis-ci.org/pwnall/node-sphero-pwn-macros.svg)](https://travis-ci.org/pwnall/node-sphero-pwn-macros)
[![API Documentation](http://img.shields.io/badge/API-Documentation-ff69b4.svg)](http://coffeedoc.info/github/pwnall/node-sphero-pwn-macros)
[![NPM Version](http://img.shields.io/npm/v/sphero-pwn-macros.svg)](https://www.npmjs.org/package/sphero-pwn-macros)

This is a [node.js](http://nodejs.org/) compiler for the
[command macros used by Sphero robots](http://sdk.sphero.com/robot-languages/macros/).

This package is intended to be used with the
[sphero-pwn node.js package](https://github.com/pwnall/node-sphero-pwn).
`sphero-pwn` is an independent effort from the official
[sphero.js](https://github.com/orbotix/sphero.js) project, and is less
supported. At the same time, we are free to develop functionality that is
unlikely to be added to the official project, such as driving a
[BB-8](http://www.sphero.com/starwars).

This project is written in [CoffeeScript](http://coffeescript.org/) and tested
using [mocha](http://visionmedia.github.io/mocha/).


## Usage

```javascript
macros = require('sphero-pwn-macros');
macro = macros.compile("rgb 255, 128, 0");
console.log(macro.bytes);
// [ 0, 7, 255, 128, 0, 0 ]
```

### Macro Language

Comments follow the Ruby / CoffeeScript / Python convention. A comment starts
with the character `#` and continues until the end of the line. There is no
multi-line comment construct.

```ruby
# This is a comment.
```

Commands are currently lowercased. Each command must be specified on its own
line. The command's arguments can be separated by spaces and optional commas.

```ruby
rgb 0 255 0    # Turn the RGB LED green.
delay 2000     # Wait for 2 seconds.
rgb 0, 0, 255  # Turn the RGB LED blue.
delay 2000     # Wait for 2 more seconds.
```

The compiler implements a simple form of variable substitution. Variable names
start with `$`, and variables are assigned values with `let`. Keep in mind that
the Spero macro language does not support variables, so the substitution is
done statically, at compilation time.

```ruby
let $red, 0
let $green, 255
let $blue, 0
rgb $red, $green, $blue  # Turn the RGB LED gren.
delay 2000               # Wait for 2 seconds.

let $blue $green
let $green $red
rgb $red, $green, $blue  # Turn the RGB LED blue
delay 2000               # Wait for 2 more seconds.
```

Macro flags can be set anywhere in the source code. However, a macro flag can
be set at most once. The supported flags are listed [here](src/flags.coffee).

```ruby
flag $exclusiveDrive 1
rgb 0 255 0    # Turn the RGB LED green.

flag $markerOnEnd, 1
```

Some commands accept built-in constants, which are syntactic sugar for
constants with special meaning. Built-ins start with `:`. The inventory of
available built-ins depends on the context that they are used in.

```ruby
flag $markerOnEnd :on  # in the context of "flag", :on is 1, :off is 0
sleep :forever         # in the context of "sleep", :forever is 0
```

### Optimizations

The PCD argument to commands is not exposed. Instead,the compiler automatically
turns `delay` commands into PCD arguments whenever it is possible to do so.
Remembering which commands accept a PCD argument is a job for computers, not
for humans.

The following example compiles to a single command (Set RGB LED, bytecode 0x07)
with a PCD argument.

```ruby
rgb 0, 255, 0
delay 200       # This sets the PCD byte for the RGB command to 200.
```

In the example below, the delay argument is too big to fit into a PCD byte, so
the compiler issues a separate delay command. Macro programmers should focus on
specifying the desired behavior, and rely on the compiler to produce the best
possible code.

```ruby
rgb 0, 0, 255
delay 2000      # 2000 is too big for the PCD byte. A delay command is issued.
```

By the same token, the compiler does not expose a separate command that maps to
the Roll2 bytecode. Instead, the compiler optimizes a `roll` command followed
by a `delay` command into a Roll (bytecode 0x05) or Roll2 (bytecode 0x1D),
depending on the `delay` argument.


### Implemented Commands

The following table summarizes the
[table used by code generation](src/commands.coffee).

| Name           | Command                  | Arguments                                         |
|----------------|--------------------------|---------------------------------------------------|
| end            | End                      | none                                              |
| endstream      | Stream End               | none                                              |
| sysdelay       | Set SD1, SD2             | register (1 or 2), delay (0 - 65535)              |
| stabilization  | Set Stabilization        | flag (:off is 0, :reset_on is 1, :on is 2)        |
| heading        | Set Heading              | heading (0 - 359)                                 |
| maxrotation    | Set Rotation Rate        | rate (0 - 255)                                    |
| roll           | Roll, Roll2              | speed (0 - 255), heading (0 - 359)                |
| rgb            | Set RGB LED              | red, green, blue (0 - 255)                        |
| backled        | Set Back LED             | power (0 - 255)                                   |
| motor          | Send Raw Motor Commands  | mode (0, 1, 2, 3, 4), power                       |
|                |                          | for mode,  :off is 0, :forward is 1,              |
|                |                          | :reverse is 2, :brake is 3, :ignore is 4          |
| delay          | Delay                    | time (0 - 65535)                                  |
| goto           | Goto                     | macroId (0 - 255)                                 |
| gosub          | Gosub                    | macroId (0 - 255)                                 |
| sleep          | Sleep                    | time (:forever is 0, :api is 65535)               |
| sysspeed       | Set SPD1, SPD2           | register (1 or 2), speed (0 - 65535)              |
| rgbfade        | Fade to LED Over Time    | red, green, blue (0 - 255), duration (0 - 65535)  |
| marker         | Emit Marker              | value (0 - 255; 0 is not recommended)             |
| waitforstop    | Wait Until Stopped       | timeout (0 -  65535)                              |
| timedrotate    | Rotate Over Time         | angularSpeed (-32767 - 32767), time (0 - 65535)   |
| repeat         | Loop Start               | count (0 - 255)                                   |
| endrepeat      | Loop End                 | none                                              |
| oncollision    | Branch On Collision      | macroId (0 - 255), :do_nothing is 0               |
| speed          | Set Speed                | speed (0 - 255)                                   |


## Development Setup

The unit tests that cover most of the compiler infrastructure can run on any
computer that has node.js installed. The integration tests that verify the
[command table](src/commands.coffee)'s correctness require a robot that can run
[orBasic](http://sdk.sphero.com/robot-languages/orbbasic/).

At the time of this writing, the [BB-8](http://www.sphero.com/starwars) does
not run orBasic. The [Sphero SPRK](http://www.sphero.com/sphero-sprk)
definitely supports orBasic. The BB-8 may never gain orBasic support, as
[the SPRK has an extra ARM core](http://www.cnet.com/news/sphero-bb-8-teardown-reveals-the-cool-robot-tech-inside-this-fun-star-wars-toy/).

Install all the dependencies.

```bash
npm install
```

List the Bluetooth devices connected to your computer.

```bash
npm start
```

Set the `SPHERO_DEV` environment variable to point to your Sphero.

```bash
export SPHERO_DEV=serial:///dev/cu.Sphero-XXX-AMP-SPP
export SPHERO_DEV=ble://ef:80:a8:4a:12:34
```

Run the tests.

```bash
npm test
```


## License

This project is Copyright (c) 2015 Victor Costan, and distributed under the MIT
License.
