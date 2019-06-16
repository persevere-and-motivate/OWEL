# OWEL
OWEL is a client- and server-side code generation utility primarily for web development. The aim of this project is to minimise the boilerplate for web development using the Haxe programming language.

## Installation
The latest version can be installed from here through haxe:

`haxelib git owel https://github.com/persevere-and-motivate/OWEL.git`

For the latest stable release, you can install directly from `haxelib`:

`haxelib install owel`

OWEL depends on `record-macros` for server-side code generation. You can install this from [here](https://github.com/HaxeFoundation/record-macros).

## Understanding the Project
OWEL contains two macro contexts, the runtime context, and the scripting language itself.

Firstly, you need to add a new line to your hxml file which uses the initialisation macro:

`--macro owel.Builder.generateTypes("owel/")`

This is the function that will begin generating either the client or server-side code depending on which target language you use. Currently, OWEL only supports PHP for the server-side and JavaScript for the client. The first argument is the folder which contains `*.owel` files that the parser within OWEL uses to generate code.

Next, for the client and server-side, you also need to `@:build` the `owel.Builder.finalise` function, like so:

```haxe
@:build(owel.Builder.finalise("owel/"))
class Main
{
    // your main entry point
}
```

Both these will generate relevant static functions within their respective contexts.

For more learning resources, including an API reference, please visit [our learning page](https://www.owelscript.co.uk/learn/).

We also have video tutorials on the following [YouTube page](https://www.youtube.com/).

## Support and Issues
Currently, if you have any queries regarding this project, please create an Issue here and we will attempt to resolve your issue as soon as possible.

## Pull Requests
We accept pull requests for bug fixes or optimisations, but we will not accept pull requests that significantly changes scripting language syntax. These requests will be ignored.

## License
We use the MIT license.