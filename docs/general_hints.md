# General Development hints

Back to the [overview](./index.md)

---

## Package Managers

A package manager can ease the development and distribution of projects.

At the point of writing there are 2 experimental-stage package managers, with
support for projects:

* [nupm](https://github.com/nushell/nupm) (by the nushell-team)
  * `potash` is not (yet) in any repository.
* [numng](https://github.com/Jan9103/numng) (by me)
  * `potash` is available as `jan9103/potash` in the offical repository.

You will also have to choose a package-format for your project (even if you only use it to install dependencies):

* `numng` package-format:
  * only supported by numng.
  * its `linkin` is easier to use than `depends` in my opinion.
    * no need to load a overlay each time you open the project.
  * compatible with [merge_nu_scripts][].
* `nupm` package format:
  * supported by both numng and nupm.
    * wider availability if used as distribution method.
    * other contributors might not want to install `numng` if they already use `nupm`.

You can switch package-formats, but you will have to rewrite almost all `use` statements.


## Releasing your project

### Using package-managers

Take a look at the respective documentation of your package-manager for this.

### As a single-file script

You can manually merge all the script files, but that can be quite tedious.  
[merge_nu_scripts][] is a script to automate this,
but be aware that it might not work flawlessly with your part of the code or other
dependencies of your project.

---

Back to the [overview](./index.md)

[merge_nu_scripts]: https://github.com/Jan9103/merge_nu_scripts
