# Node.js Macro Compiler for Sphero Robots

[![Build Status](https://travis-ci.org/pwnall/node-sphero-pwn-macros.svg)](https://travis-ci.org/pwnall/node-sphero-pwn-macros)
[![API Documentation](http://img.shields.io/badge/API-Documentation-ff69b4.svg)](http://coffeedoc.info/github/pwnall/node-sphero-pwn-macros)
[![NPM Version](http://img.shields.io/npm/v/sphero-pwn.svg)](https://www.npmjs.org/package/sphero-pwn-macros)

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


## Development Setup

The basic compiler tests can run on any computer. The integration tests
require a robot that can run
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
