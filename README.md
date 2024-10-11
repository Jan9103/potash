# Potash

A [nushell][] TerminalUserInterface library inspired by [i3wm](https://i3wm.org/) and [dvtm](https://github.com/martanne/dvtm).

---

| **PROJECT STATUS** | It is a proof-of-concept for the lowest-level-api. Expect everything to change. |
| --- | --- |

If you want to use it now pin a exact version in your package-manager and expect to have to rewrite a lot until it reaches version 1.0.

Low-Level problems, which still have to be implemented:
* Cross-panel communication (file-list on the left, file-preview on the right)
  * currently possible via `custom-wrapper-pannel[hsplit[file-list, preview]]` and manipulating the contents from the wrapper
  * maybe a `global_variables` dictionary?
* Floating windows

TODO: High-level API

---

## Usage

**WIP** the part below is a WIP documentation, which i'll finish when it reaches 1.0.  
For now use `example.nu` as a template.

### Panels

Everything in potash is a panel.  
Every panel implements a function, which will render graphics for the provided size and width.  

Example:
```
$ panel text --help
panel text <lines of text>

$ panel render --help
panel render <panel> <width> <height>

$ panel render (panel text ["hi"]) 2 1 | str join "\n"
hi
```

### Splits

In order to render multiple panels at once you can use `hsplit` (horizontal split) and `vsplit`
panels, which can contain multiple panels and will render those.

Example:
```
$ panel hsplit --help
panel hsplit <...panels>

$ panel render (panel hsplit (panel text ["hi"]) (panel text ["hi"])) 7 1 | str join "\n"
hi │ hi
```

### Available Panels

* `potash/panels.nu text`: render static text-lines
* `potash/panels.nu hsplit`: horizontal split
* `potash/panels.nu vsplit`: vertical split
* `potash/panels.nu titled`: add a title to a panel
* `potash/panels.nu generator`: provide your own code to render this panels content


## Inner Workings

```nu
let panel = {
  "T": "Type-Name"
  "data": {}  # specific to type. mutable storage
  "render": {|data,width,height,active| ["", ""]}  # render implementation for type.
                                                   # the base-types are implemented in `render_panel` instead
                                                   # in order to save storage, etc
  "handle_input": {|data,input|
    # data = $panel.data
    # input = result of `input listen`

    {  # return: everything is optional and only active in included
      "data": $data    # if included this will override the old $panel.data
      "handled": true  # used to let parent-panels handle it instead
      "return": {}     # a dict, which can contain anything. used to pass info to a parent panel
      "exit": any      # return value of the base-function
    }
  }
  "selectable": {|| true}  # is selectable?
}
```


## FAQ

**Q:** Why this name?  
**A:** I wrote a LLM `potato` and took the first word from its response, which i did not know.

[nushell]: https://nushell.sh
