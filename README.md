# OWEL
OWEL is a client- and server-side code generation utility primarily for web development. The aim of this project is to minimise the boilerplate for web development using the Haxe programming language.

Currently, this version of OWEL supports Haxe 3.x or later. Newer versions may at any point require the use of Haxe 4.0 when it is released.

## Roadmap

 * Generate Typedef and Server Class definitions ![img](img/tick.png)
 * Generate RESTful function notation in server class definitions
 * Add ability to customise macro options
 * Add File Upload options
 * Implement a Router in some form ![img](img/tick.png)

## Installation
The latest version can be installed from here through haxe:

`haxelib git owel https://github.com/persevere-and-motivate/OWEL.git`

OWEL depends on `record-macros` for server-side code generation. You can install this from [here](https://github.com/HaxeFoundation/record-macros).

Include in your `*.hxml` file:

`-lib owel`

## Understanding the Project
OWEL contains a macro context and the scripting language itself.

Firstly, you need to add a new line to your hxml file which uses the initialisation macro:

`--macro owel.Builder.generateTypes("owel/")`

This is the function that will begin generating either the client or server-side code depending on which target language you use. The first argument is the folder which contains `*.owel` files that the parser within OWEL uses to generate code.

Generated server types automatically get the `@:build(owel.Builder.finalise())` meta option which generates static functions that use the class type for instances.

## Creating an OWEL file
`*.owel` files have very simple structure:

```
structure User
@ID "ID" :hidden
@TextField "Username"
@TextField "Hash"
```

Let's break this down:

 1. The first line is our `structure` definition. This is required for defining our types. Without it, the parser will not know the name to use to define our structures - it will also throw an error at compile-time.
 2. On the second line and after contains our field definitions.
 3. Field Types are prefixed with the `@` symbol. There are a few of them: `ID`, `TextField`, `TextArea`, `Date`, `Time`, `DateTime`, `Numeric`, `CheckBox` and `ComboBox`. At some point, there will be more options and eventually the ability to add your own.
 4. After the Field Type, you must add in quotation marks the display value or name of the field. This is required by the parser. You may optionally add an option, like in the first field.
 5. Options are prefixed with `:` using key-value notation. Keys cannot have spaces. Values can be a string or any series of characters without quotations. If you want to use reserved characters, always wrap your values in a string. You cannot mix them both. For example: `@TextField "Username" : id = "username"`.
 6. In the above option example, this is unnecessary as the parser will generate the equivalent member name anyway. However, the `id` option is used in this instance to generate a different type value name if you wish. The Display Value in quotations may be passed through to runtime (in a later version) for display purposes.
 7. Options can be on multiple lines, but the key-value pair must be on the same line. Eventually, when the macro API becomes available, you will be able to define how code is generated based on certain field options.

## API
There is also a runtime API, but currently only for client-side server requests in the `owel.Request` class.

## Support and Issues
Currently, if you have any queries regarding this project, please create an Issue here and we will attempt to resolve your issue as soon as possible.

## Pull Requests
We accept pull requests for bug fixes or optimisations, but we will not accept pull requests that significantly changes scripting language syntax. These requests will be ignored.

## License
We use the MIT license.