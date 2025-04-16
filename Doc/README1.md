# ShellSpec: full-featured BDD unit testing framework

ShellSpec is a **full-featured [BDD](https://en.wikipedia.org/wiki/Behavior-driven_development) unit testing framework** for dash, bash, ksh, zsh and **all POSIX shells** with code coverage, mocking, parameterized testing, parallel execution and more. Developed for **cross-platform shell scripts and shell script libraries**, it provides practical CLI features and a powerful syntax for shell script testing.

----

## Project directory

All specfiles must be under the project directory with a `.shellspec` file at the root. This file specifies default options, but an empty file is sufficient if no options are needed.

NOTE: The `.shellspec` file was described in documentation as optional for some time, but starting with version 0.28.0, this file is checked and required.

Create necessary files by executing `shellspec --init` in an existing directory.

### Typical directory structure

Version 0.28.0 allows customization with options, supporting flexible [directory structure](docs/directory_structure.md).

```text
<PROJECT-ROOT> directory
├─ .shellspec                       [mandatory]
├─ .shellspec-local                 [optional] Ignore from version control
├─ .shellspec-quick.log             [optional] Ignore from version control
├─ report/                          [optional] Ignore from version control
├─ coverage/                        [optional] Ignore from version control
│
├─ bin/
│   ├─ your_script1.sh
│              :
├─ lib/
│   ├─ your_library1.sh
│              :
│
├─ spec/ (also <HELPERDIR>)
│   ├─ spec_helper.sh               [recommended]
│   ├─ banner[.md]                  [optional]
│   ├─ support/                     [optional]
│   │
│   ├─ bin/
│   │   ├─ your_script1_spec.sh
│   │             :
│   ├─ lib/
│   │   ├─ your_library1_spec.sh
```

### Options file

For default options, create options file(s). Files are read in this order (later options take precedence):

1. `$XDG_CONFIG_HOME/shellspec/options`
2. `$HOME/.shellspec-options` (version >= 0.28.0) or `$HOME/.shellspec` (deprecated)
3. `<PROJECT-ROOT>/.shellspec`
4. `<PROJECT-ROOT>/.shellspec-local` (Do not store in VCS such as git)

Specify user defaults with `$XDG_CONFIG_HOME/shellspec/options` or `$HOME/.shellspec-options`, 
project defaults with `.shellspec`, and personal overrides with `.shellspec-local`.

### `.shellspec` - project options file

Specifies the default options to use for the project.

### `.shellspec-local` - user custom options file

Override the default options used by the project with your preferences.

### `.shellspec-basedir` - specfile execution base directory

Specifies the directory where specfile will run.
See [directory structure](docs/directory_structure.md) or `--execdir` option for details.

### `.shellspec-quick.log` - quick execution log

If present, enables Quick mode and records execution logs.
Created automatically with `--quick` option.
Delete this file to turn off Quick mode.

### `report/` - report file directory

Output location for reports from `--output` or `--profile` options.
Configurable with `--reportdir` option.

### `coverage/` - coverage reports directory

Output location for coverage reports.
Configurable with `--covdir` option.

### `spec/` - (default) specfiles directory

By default, specfiles are stored under the `spec` directory,
though multiple directories with different names are possible.

NOTE: In Version <= 0.27.x, `spec` was the only directory for specfiles.

### \<HELPERDIR\> (default: `spec/`)

Directory for `spec_helper.sh` and other files.
By default, the `spec` directory also serves as `HELPERDIR`,
but can be changed with the `--helperdir` option.

#### `spec_helper.sh` - (default) helper file for specfile

Loaded by the `--require spec_helper` option.
Used for global functions, initial settings, custom matchers, etc.

#### `banner[.md]` - banner file displayed at test execution

If `<HELPERDIR>/banner` or `<HELPERDIR>/banner.md` exists, displays a banner when
the `shellspec` command runs. Use for information about the tests.
Disable with `--no-banner` option.

#### `support/` - directory for support files

Stores custom matchers and tasks.

##### `bin` - directory for support commands

Stores [support commands](#support-commands).

## Specfile (test file)

Tests are written in specfiles.
By default, these are files ending with `_spec.sh` under the `spec` directory.

Specfiles run using the `shellspec` command, but can also be executed directly.
See [self-executable specfile](#self-executable-specfile) for details.

### Example

```sh
Describe 'lib.sh' # example group
  Describe 'bc command'
    add() { echo "$1 + $2" | bc; }

    It 'performs addition' # example
      When call add 2 3 # evaluation
      The output should eq 5  # expectation
    End
  End
End
```

**The best place to learn how to write a specfile is the
[examples/spec](examples/spec) directory. You should take a look at it!**
*(Those examples include failure examples on purpose.)*

### About DSL

ShellSpec has its own DSL for tests. While it uses capitalized keywords,
the syntax is compatible with shell scripts. You can embed
shell functions and use [ShellCheck](https://github.com/koalaman/shellcheck) to check syntax.

The capitalized DSL keywords prevent confusion with commands and provide
features like scoping, shell-independent line numbers, and workarounds for shell bugs.

### Execution directory

Since version 0.28.0, specfiles run from the project root directory by default,
even when executed from subdirectories.
Before 0.27.x, they ran from the current directory.

Change this with `--execdir @LOCATION[/DIR]` option.
Available locations (cannot specify directories outside the project):

- `@project`   Where the `.shellspec` file is located (project root) [default]
- `@basedir`   Where the `.shellspec` or `.shellspec-basedir` file is located
- `@specfile`  Where the specfile is located

With `@basedir`, the parent directory containing `.shellspec-basedir` or `.shellspec` 
becomes the execution directory. This helps when testing multiple utilities separately.

NOTE: You must be in the project directory or use `-c` (`--chdir`) or
`-C` (`--directory`) option before running specfiles.

### Embedded shell scripts

You can embed shell functions in specfiles for test preparation and complex testing.

Specfiles implement scope using subshells.
Functions defined in a specfile can only be used within blocks (e.g. `Describe`, `It`).

For global functions, define them in `spec_helper.sh`.

### Translation process

Specfiles are translated into regular shell scripts in a temporary directory (default: `/tmp`) 
before execution.

Translation primarily replaces forward-matched DSL words, with some exceptions.
To see the translated code, use `shellspec --translate`.

### Syntax formatter (`altshfmt`)

For formatting specfiles with DSLs, use [altshfmt](https://github.com/shellspec/altshfmt)
instead of general shell formatters.

## DSL syntax

### Basic structure

#### `Describe`, `Context`, `ExampleGroup` - example group block

`ExampleGroup` groups examples. `Describe` and `Context` are aliases.
They can be nested and may contain other example groups or examples.

```sh
Describe 'is example group'
  Describe 'is nestable'
    ...
  End

  Context 'is used to facilitate understanding depending on the context'
    ...
  End
End
```

Example groups can be tagged. See [Tagging](#tagging) for details.

```sh
Describe 'is example group' tag1:value1 tag2:value2 ...
```

#### `It`, `Specify`, `Example` - example block

`Example` holds evaluations and expectations.
`It` and `Specify` are aliases.

An example can have one evaluation and multiple expectations.

```sh
add() { echo "$1 + $2" | bc; }

It 'performs addition'          # example
  When call add 2 3             # evaluation
  The output should eq 5        # expectation
  The status should be success  # another expectation
End
```

Examples can be tagged. See [Tagging](#tagging) for details.

```sh
It 'performs addition' tag1:value1 tag2:value2 ...
```

#### `Todo` - one liner empty example

`Todo` is an empty example treated as a [pending](#pending---pending-example) example.

```sh
Todo 'will be used later when we write a test'

It 'is an empty example, the same as Todo'
End
```

#### `When` - evaluation

Evaluation executes a function or command for verification.
Only one evaluation per example, and it's optional.

See more details in [Evaluation](docs/references.md#evaluation)

NOTE: [About executing aliases](#about-executing-aliases)

##### `call` - call a shell function (without subshell)

Calls a function without subshell.
Can also run commands.

```sh
When call add 1 2 # call `add` shell function with two arguments.
```

##### `run` - run a command (within subshell)

Runs a command within subshell. Can also call shell functions.
Not limited to shell scripts.

NOTE: This does not support coverage measurement.

```sh
When run touch /tmp/foo # run `touch` command.
```

Some commands have special handling:

###### `command` - runs an external command

Runs a command, respecting shebang.
Cannot call shell functions. Not limited to shell scripts.

NOTE: This does not support coverage measurement.

```sh
When run command touch /tmp/foo # run `touch` command.
```

###### `script` - runs a shell script

Runs a shell script, ignoring shebang. Must be a shell script.
Executes in another instance of the same shell.

```sh
When run script my.sh # run `my.sh` script.
```

###### `source` - runs a script by `.` (dot) command

Sources a shell script, ignoring shebang. Must be a shell script.
Similar to `run script`, but allows function-based mocking.

```sh
When run source my.sh # source `my.sh` script.
```

##### About executing aliases

Executing aliases requires `eval`:

```sh
alias alias-name='echo this is alias'
When call alias-name # alias-name: not found

# eval is required
When call eval alias-name

# When using embedded shell scripts
foo() { eval alias-name; }
When call foo
```

#### `The` - expectation

Expectations begin with `The` and verify results:

```sh
The output should equal 4
```

Use `should not` for opposite verification:

```sh
The output should not equal 4
```

##### Subjects

The subject is the verification target:

```sh
The output should equal 4
      |
      +-- subject
```

Available subjects: `output` (`stdout`), `error` (`stderr`), `status`, `variable`, `path`, etc.

See [Subjects](docs/references.md#subjects) for details.

##### Modifiers

Modifiers refine the verification target:

```sh
The line 2 of output should equal 4
      |
      +-- modifier
```

Modifiers are chainable:

```sh
The word 1 of line 2 of output should equal 4
```

Ordinal numerals can replace numbers:

```sh
The first word of second line of output should equal 4
```

Available modifiers: `line`, `word`, `length`, `contents`, `result`, etc.
The `result` modifier makes a user-defined function's result the subject.

See [Modifiers](docs/references.md#modifiers) for details.

##### Matchers

Matchers perform verification:

```sh
The output should equal 4
                   |
                   +-- matcher
```

Available matchers: string matchers, status matchers, variable matchers, stat matchers.
The `satisfy` matcher verifies with user-defined functions.

See [Matchers](docs/references.md#matchers) for details.

##### Language chains

Language chains improve readability without affecting verification: `a`, `an`, `as`, `the`.

These sentences have the same meaning:

```sh
The first word of second line of output should valid number

The first word of the second line of output should valid as a number
```

#### `Assert` - expectation for custom assertion

`Assert` verifies with a user-defined function.
For verifying side effects, not the evaluation result.

```sh
still_alive() {
  ping -c1 "$1" >/dev/null
}

Describe "example.com"
  It "responses"
    Assert still_alive "example.com"
  End
End
```

### Pending, skip and focus

#### `Pending` - pending example

`Pending` makes tests pass if verification fails and fail if verification succeeds.
Useful for marking future implementations.

```sh
Describe 'Pending'
  Pending "not implemented"

  hello() { :; }

  It 'will success when test fails'
    When call hello world
    The output should "Hello world"
  End
End
```

#### `Skip` - skip example

Skip executing examples:

```sh
Describe 'Skip'
  Skip "not exists bc"

  It 'is always skip'
    ...
  End
End
```

##### `if` - conditional skip

Skip conditionally:

```sh
Describe 'Conditional skip'
  not_exists_bc() { ! type bc >/dev/null 2>&1; }
  Skip if "not exists bc" not_exists_bc

  add() { echo "$1 + $2" | bc; }

  It 'performs addition'
    When call add 2 3
    The output should eq 5
  End
End
```

#### 'x' prefix for example group and example

##### `xDescribe`, `xContext`, `xExampleGroup` - skipped example group

Skip execution of all examples in these blocks:

```sh
Describe 'is example group'
  xDescribe 'is skipped example group'
    ...
  End
End
```

##### `xIt`, `xSpecify`, `xExample` - skipped example

Skip execution of these examples:

```sh
xIt 'is skipped example'
  ...
End
```

#### 'f' prefix for example group and example

##### `fDescribe`, `fContext`, `fExampleGroup` - focused example group

Only examples in these blocks are executed when using `--focus`:

```sh
Describe 'is example group'
  fDescribe 'is focus example group'
    ...
  End
End
```

##### `fIt`, `fSpecify`, `fExample` - focused example

Only these examples are executed when using `--focus`:

```sh
fIt 'is focused example'
  ...
End
```

#### About temporary pending and skip

Using `Pending` or `Skip` without a message is considered "temporary".
"x"-prefixed groups/examples are also temporary skips.

Non-temporary `Pending` and `Skip` (with messages) signal long-term issues
and may be committed to version control. Temporary versions should be for current work only.

The types differ in report display. See `--skip-message` and `--pending-message` options.

```sh
# Temporary pending and skip
Pending
Skip
Skip # this comment will be displayed in the report
Todo
xIt
  ...
End

# Non-temporary pending and skip
Pending "reason"
Skip "reason"
Skip if "reason" condition
Todo "It will be implemented"
```

### Hooks

#### `BeforeEach` (`Before`), `AfterEach` (`After`) - example hook

Run commands before/after each example:

```sh
Describe 'example hook'
  setup() { :; }
  cleanup() { :; }
  BeforeEach 'setup'
  AfterEach 'cleanup'

  It 'is called before and after each example'
    ...
  End

  It 'is called before and after each example'
    ...
  End
End
```

NOTE: `BeforeEach` and `AfterEach` are in version 0.28.0+.
Earlier versions use `Before` and `After`.

NOTE: `AfterEach` is for cleanup, not assertions.

#### `BeforeAll`, `AfterAll` - example group hook

Run commands before/after all examples in a group:

```sh
Describe 'example all hook'
  setup() { :; }
  cleanup() { :; }
  BeforeAll 'setup'
  AfterAll 'cleanup'

  It 'is called before/after all example'
    ...
  End

  It 'is called before/after all example'
    ...
  End
End
```

#### `BeforeCall`, `AfterCall` - call evaluation hook

Run commands before/after call evaluation:

```sh
Describe 'call evaluation hook'
  setup() { :; }
  cleanup() { :; }
  BeforeCall 'setup'
  AfterCall 'cleanup'

  It 'is called before/after call evaluation'
    When call hello world
    ...
  End
End
```

NOTE: These were created for testing ShellSpec itself.
Use `BeforeEach`/`AfterEach` when possible.

#### `BeforeRun`, `AfterRun` - run evaluation hook

Run commands before/after run evaluations
(`run`, `run command`, `run script`, `run source`):

```sh
Describe 'run evaluation hook'
  setup() { :; }
  cleanup() { :; }
  BeforeRun 'setup'
  AfterRun 'cleanup'

  It 'is called before/after run evaluation'
    When run hello world
    ...
  End
End
```

These hooks execute in the same subshell as the run evaluation,
allowing access to variables after execution.

NOTE: These were created for testing ShellSpec itself.
Use `BeforeEach`/`AfterEach` when possible.

#### Pitfalls

Hooks may fail if there's stderr output, even with exit code 0.

Commands like `git checkout` write to stderr without failing,
so be aware hooks may fail because of this.

### Helpers

#### `Dump` - dump stdout, stderr, and status for debugging

Shows stdout, stderr, and status of evaluations:

```sh
When call echo hello world
Dump # stdout, stderr and status
```

#### `Include` - include a script file

Include a shell script for testing:

```sh
Describe 'lib.sh'
  Include lib.sh # hello function defined

  Describe 'hello()'
    It 'says hello'
      When call hello ShellSpec
      The output should equal 'Hello ShellSpec!'
    End
  End
End
```

#### `Set` - set shell options

Set shell options before executing examples.
Options use the long name of `set` or name of `shopt`:

NOTE: Use `Set` instead of `set` command for better cross-shell compatibility.

```sh
Describe 'Set helper'
  Set 'errexit:off' 'noglob:on'

  It 'sets shell options before executing the example'
    When call foo
  End
End
```

#### `Path`, `File`, `Dir` - path alias

Define short pathname aliases:

```sh
Describe 'Path helper'
  Path hosts-file="/etc/hosts"

  It 'defines short alias for long path'
    The path hosts-file should exist
  End
End
```

`File` and `Dir` are aliases for `Path`.

#### `Data` - pass data as stdin to evaluation

Input data from stdin using block syntax:

```sh
Describe 'Data helper'
  It 'provides with Data helper block style'
    Data # Use Data:expand instead if you want expand variables.
      #|item1 123
      #|item2 456
      #|item3 789
    End
    When call awk '{total+=$2} END{print total}'
    The output should eq 1368
  End
End
```

You can also use files, functions or strings as data sources.

See [Data](docs/references.md#data) for details.

#### `Parameters` - parameterized example

Run the same test with different parameters:

```sh
Describe 'example'
  Parameters
    "#1" 1 2 3
    "#2" 1 2 3
  End

  Example "example $1"
    When call echo "$(($2 + $3))"
    The output should eq "$4"
  End
End
```

Additional styles: `Parameters:value`, `Parameters:matrix`, `Parameters:dynamic`.

See [Parameters](docs/references.md#parameters) for details.

NOTE: You can combine `Parameters` and `Data:expand` helpers.

#### `Mock` - create a command-based mock

See [Command-based mock](#command-based-mock)

#### `Intercept` - create an intercept point

See [Intercept](#intercept)

## Mocking

Two types of mocks are available: function-based and command-based.
Function-based mocks are recommended for performance.
Both can be overwritten within blocks and restore when blocks end.

### Function-based mock

Simply (re)define a shell function:

```sh
Describe 'function-based mock'
  get_next_day() { echo $(($(date +%s) + 86400)); }

  date() {
    echo 1546268400
  }

  It 'calls the date function'
    When call get_next_day
    The stdout should eq 1546354800
  End
End
```

### Command-based mock

Creates a temporary script that runs as an external command:

```sh
Describe 'command-based mock'
  get_next_day() { echo $(($(date +%s) + 86400)); }

  Mock date
    echo 1546268400
  End

  It 'runs the mocked date command'
    When call get_next_day
    The stdout should eq 1546354800
  End
End
```

This is slower but has advantages:

- Can use invalid characters in function names
  - e.g. `docker-compose` (`-` is invalid in POSIX function names)
- Can be invoked from external commands (not just shell scripts)

Restrictions:

- Cannot mock shell functions or built-ins
- Cannot call shell functions outside the `Mock` block
  - Exception: exported functions in bash (`export -f`)
- Variables outside the block must be exported
- Use `%preserve` directive to return variables

NOTE: This works by prepending a mock commands directory to `PATH`.

## Support commands

```sh
#!/bin/sh -e
# Command name: @sed
. "$SHELLSPEC_SUPPORT_BIN"
case $OSTYPE in
  *darwin*) invoke gsed "$@" ;;
  *) invoke sed "$@" ;;
esac
```

## spec_helper

Used for shell options, global functions, execution shell checks, custom matchers, etc.

The default module name is `spec_helper`. You can use multiple modules with different names.
Only POSIX identifier characters can be used in module names.
Module files must have the `.sh` extension.
Loaded from `SHELLSPEC_LOAD_PATH` using `--require` option.

A typical `spec_helper` with three callback functions:

```sh
# Filename: spec/spec_helper.sh

set -eu

spec_helper_precheck() {
  minimum_version "0.28.0"
  if [ "$SHELL_TYPE" != "bash" ]; then
    abort "Only bash is supported."
  fi
}

spec_helper_loaded() {
  : # In most cases, you won't use it.
}

spec_helper_configure() {
  import 'support/custom_matcher'
  before_each "global_before_each_hook"
}

# User-defined global function
global_before_each_hook() {
  :
}

```

The `spec_helper` loads at least twice: once during precheck (before specfile execution)
and again at the beginning of specfile execution.
With parallel execution, it loads for each specfile.

Helper functions are available within callbacks but not outside them.
Callbacks are removed when loading completes. User-defined functions are preserved.

### `<module>_precheck`

Invoked once before loading specfiles.
Exit with `exit`/`abort` or `return` non-zero to prevent specfile execution.
The function runs with `set -eu`, so explicit error returns aren't needed.

Changes made here don't affect specfiles since it runs in a separate process.

#### `minimum_version`

- Usage: `minimum_version <version>`

Specifies the minimum ShellSpec version required.
Uses [semantic versioning](https://semver.org/) format.
Pre-release versions have lower precedence than normal versions.
Build metadata is ignored.

NOTE: Since `<module>_precheck` is only in 0.28.0+,
it can run with earlier versions if specified.
For version checking in older versions, use `--env-from`:

```sh
# spec/env.sh
# Add `--env-from spec/env.sh` to `.shellspec`
major_minor=${SHELLSPEC_VERSION%".${SHELLSPEC_VERSION#*.*.}"}
if [ "${major_minor%.*}" -eq 0 ] && [ "${major_minor#*.}" -lt 28 ]; then
  echo "ShellSpec version 0.28.0 or higher is required." >&2
  exit 1
fi
```

#### `error`, `warn`, `info`

- Usage: `error [messages...]`
- Usage: `warn [messages...]`
- Usage: `info [messages...]`

Output messages by type. You can also use `echo` or `printf`.

#### `abort`

- Usage: `abort [messages...]`
- Usage: `abort <exit status> [messages...]`

Display error and exit. Default exit status is 1.
Using `exit 0` exits normally without running specfiles.

#### `setenv`, `unsetenv`

- Usage: `setenv [name=value...]`
- Usage: `unset [name...]`

Pass or remove environment variables from precheck to specfiles.

#### environment variables

Available environment variables:

- `VERSION` - ShellSpec Version
- `SHELL_TYPE` - Currently running shell type (e.g. `bash`)
- `SHELL_VERSION` - Currently running shell version (e.g. `4.4.20(1)-release`)

NOTE: Don't confuse `SHELL_TYPE` with `SHELL` environment variable.
`SHELL` represents the user login shell, not the current running shell.

### `<module>_loaded`

Called after loading ShellSpec internal functions but before
loading core modules (subject, modifier, matcher, etc).
With parallel execution, may be called multiple times in isolated processes.
Internal `shellspec_` functions can be used, but may change between versions.

Created for [workarounds](helper/ksh_workaround.sh) in specific shells when
testing ShellSpec itself. Other uses are uncommon but possible.

### `<module>_configure`

Called after core modules load.
With parallel execution, may be called multiple times in isolated processes.
Internal `shellspec_` functions can be used, but may change between versions.
Used for global hooks, custom matchers, and overriding core functions.

#### `import`

- Usage: `import <module> [arguments...]`

Import a custom module from `SHELLSPEC_LOAD_PATH`.

#### `before_each`, `after_each`

- Usage: `before_each [hooks...]`
- Usage: `after_each [hooks...]`

Register hooks to run before/after every example.
Equivalent to adding `BeforeEach`/`AfterEach` at the top of all specfiles.

#### `before_all`, `after_all`

- Usage: `before_all [hooks...]`
- Usage: `after_all [hooks...]`

Register hooks to run before/after all examples.
Equivalent to adding `BeforeAll`/`AfterAll` at the top of all specfiles.

NOTE: These run before/after each specfile, not all specfiles collectively.

## Code Coverage

ShellSpec has integrated coverage using [Kcov](https://github.com/SimonKagstrom/kcov) (v38+).


### Measurement target

ShellSpec measures only necessary code for better performance.
Some items cannot be measured due to implementation:

- Shell scripts loaded by `Include` are measured
- Shell functions called by `When` evaluation are measured
- Shell scripts executed by `When run script` are measured
- Shell scripts executed by `When run source` are measured
- External commands executed by `When` are NOT measured
  - Even shell scripts aren't measured when executed as external commands
- Anything else is not measured

By default, only files with `.sh` in the name are targeted.
Include other files by adjusting `--kcov-options`:

```sh
# Default kcov (coverage) options
--kcov-options "--include-path=. --path-strip-level=1"
--kcov-options "--include-pattern=.sh"
--kcov-options "--exclude-pattern=/.shellspec,/spec/,/coverage/,/report/"

# Example: Include script "myprog" with no extension
--kcov-options "--include-pattern=.sh,myprog"

# Example: Only specified files/directories
--kcov-options "--include-pattern=myprog,/lib/"
```

### Coverage report

Kcov generates coverage reports, `cobertura.xml` and `sonarqube.xml` files
in the coverage directory. These integrate with [Coveralls](https://coveralls.io/),
[Code Climate](https://codeclimate.com/), [Codecov](https://codecov.io/), etc.


