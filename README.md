# Fathom

Fathom is a speedy, sexy JS/CoffeeScript game development library. 

## Checkout

First, clone our project!

`git clone --recursive git://github.com/sarenji/fathom.git`.

## Install dependencies

You need our dependencies in order to run tests and compile CoffeeScript to JavaScript.

`npm install`

You do not need dependencies to use our library or run our game.

Only the `fathom.coffee` file is necessary for use. A script is coming so that people without CoffeeScript can compile our CoffeeScript.

## Recipes

For development: `git clone git://github.com/sarenji/fathom.git`.

Development with the example game: `git clone --recursive git://github.com/sarenji/fathom.git`.

Just want the example game by itself? `git clone git://github.com/johnfn/depths.git`.

## Depths

Fathom comes with the example game Depths, which is intended to demonstrate how to use Fathom. If you cloned the development version without using the `--recursive` option, but now want the example game, type this command:

`git submodule update --init`

Then open `depths/index.html` in your favorite web browser. Bam! Game.

## Tests

Run all test suites via `cake test`.

Run tests continuously via `cake autotest`.
