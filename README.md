# Potash

| **PROJECT STATUS** | It is a proof-of-concept for the lowest-level-api. Expect everything to change. |
| --- | --- |

A [nushell][] TerminalUserInterface library inspired by [i3wm][] and [dvtm][].

Let me disappoint you, before you get invested to much:

* Potash is single-threaded. Therefore you have to choose between a fixed refresh rate and user interaction.
* While it isn't necesarely ugly, it has some rough (unsmoothed) edges.
  * It is not planned to sacrifice simplicity for design in the standard-library.
    * It should however be possible to write a `smart-border-connector-wrapper-panel` or create alternatives to the builtin panels.
  * [ratatui][], [fzf][], and similar will look better.

Goals:

* Modularity.
  * Tiling, Titles, Text, etc all get treated the same way.
* Simplicity.
  * No "smart" border connectors, etc.
  * Splitting instead of coordinates or similar.
* Extensibility.
  * Everything done internally could be done by a extension as well.
* Hackability.
  * The internals of each component are documented and can be manipulated.
* 100% native nu-script.


## Usage

**NOTE:** It is strongly recommended to pin a specific version (no "or newer") if you use a package-manager.

Potash is split into multiple parts:

* A low-level API:
  * **Status:** Early prototype.
  * **Pro:** You can control everything.
  * **Con:** Creating a basic interface can take many linex of code.
  * [documentation](./docs/low_level/index.md)
* A high-level API:
  * **Status:** Not yet implemented.
  * **Pro:** It's easy to create a interface for common tasks in a single line.
  * **Con:** Uncommon tasks might not be implemented.
  * [documentation](./docs/high_level/index.md)

## Roadmap

### 0.1.0 (alpha 1.0)

* [ ] documentation
* [ ] find a good code-structure
* [ ] a few high-level API commands (for testing)
  * [ ] select_with_preview
* [ ] snippets for generating text
  * [ ] progress-bar


## FAQ

**Q:** Why this name?  
**A:** I wrote a LLM `potato` and took the first word from its response, which i did not know.

[dvtm]: https://github.com/martanne/dvtm
[fzf]: https://github.com/junegunn/fzf
[i3wm]: https://i3wm.org
[nushell]: https://nushell.sh
[ratatui]: https://github.com/ratatui/ratatui
