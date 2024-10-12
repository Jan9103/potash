# (3) Creating own panel types

Chapter Overview: [index](./index.md)  
Previous Chapter: [Builtin Panels](./internal_panels.md)

* (3.1) [A minimal Panel](#c3.1)
* (3.2) [Interactivity](#c3.2)
* (3.3) [Sub-Panels](#c3.3)
* (3.4) [Contribute to Builtin panels](#c3.4)

---

Panels in potash are `records` with certain values filled in.  
All `potash/panel.nu text` does is fill in a new record with the values you
provided and the `text`-panel code\*.

<a name="c3.1"></a>

## (3.1) A minimal Panel

```nu
use potash/panel.nu fix_size

def my_panel []: nothing -> record {{
  "T": "my_panel"
  "data": {}
  "render": {|data,width,height,is_active|
    fix_size ["Hello World!"] $width $height
  }
}}
```

**T** is the panel type.
This is used for more efficient handling of internal panels and to help identify what is
what during debugging.  
Therefore you can use anything, except for the names used internally.

**data** is the place, where you should store all variables you need to render the panel.  
You can fill it with anything you want and update its values when the user
interacts with your panel.  
Example usecases:

* Seperator character for `hsplit` and `vsplit`.
* Text-buffer fox a text-editor.
* Selected index for `list_item_selector`.

**render** is the function/closure responsible for rendering the panel.  
It recieves the following arguments:

* `data` (record): the `data` field of your panel (not mutable!)
* `width` (int): the expected width of your output
* `height` (int): the expected height of your output
* `is_active` (bool): is your panel currently selected by the user? (can be used to gray it out)

Return type: A `$height` long list of `$width` visual-length strings.  
What is visual-length? Strings can contain graphemes, which are 2 (or more) bytes long characters,
which get rendered as 1 character. ANSI codes are also multiple characters of text, which do not
are not visible to the user. Visual-length takes both graphemes and ANSI into account.

In thes case we used `potash/panel.nu fix_size` to force the return value `["Hello World!"]` into
the correct size.

<a name="c3.2"></a>

## (3.2) Interactivity

Lets say we want to make a interactive panel, which counts how often you have
pressed the `space` key.

```nu
use potash/panel.nu fix_size

def space_key_counter_panel []: nothing -> record {{
  "T": "space_key_press_counter"
  "data": {"count": 0}
  "render": {|data,width,height,is_active|
    let color = (if $is_active {"green"} else {"white"})
    fix_size [$"(ansi $color)($data.count)"] $width $height
  }
  "selectable": {|data| true}
  "handle_input": {|data,input|
    if $input.code? == "space" {{
      "handled": true
      "data": ($data | update count ($data.count + 1))
    }} else {{
      "handled": false
    }}
  }
}}
```

In **data** we now initialize a variable `count` as 0 for later use.

**render** has also changed a bit:  
Since this window is (de-)selectable we use the `$is_active` variables
value to make this information visible to the end-user.  
We also make use of the `count` variable from `data` and display it to
the user.

**selectable** is a function, which's return value indicates weather or not
a panel can be interacted with.  
This information is used by panels like `vsplit` to skip it when the user
switches panels.  

**handle_input** handles ALL user interaction when the panel is selected.  
It is a function, which recieves its `data` and the user interaction
(in `input listen` format) as arguments.  
Please keep in mind that `input listen` does not only include keyboard input,
but also mouse clicks and movement. Therefore you will have to access
values like `code` as optional values (`$input.code?`) and expect it to
potentially return `null`.

The return value of this function is a record with the following optional keys:

Name      | Data-Type | Fallback | Description
--------- | --------- | -------- | -----------
`handled` | bool      | `false`  | did the panel handle the user-input? if `false` parent panels like `vsplit` will try to handle them.
`data`    | record    | old `$data` | a updated version of `data`.
`return`  | any       |          | a return value. this can for example be used by a selector when the user presses return.

In this cases we just update the `data` with the new number.  
We could use `"data": {"count": ($data.count + 1)}` instead of the current implementation.
I just wrote it with `update` to make you aware that this is the best-practise with more
complex panels to avoid loosing data.

There are also a few constants containing key-code lists for common actions available:
* direction (including vim-bindings, etc): `potash/panel.nu`: `UP_KEY_CODES`, `DOWN_KEY_CODES`, `LEFT_KEY_CODES`, `RIGHT_KEY_CODES`

<a name="c3.3"></a>

## (3.3) Sub-panels

It is absolutely possible to have sub-panels, which is how `vsplit`, `hsplit`, `titled`, etc work.

Since this is a fairly common thing there are "helper" functions to make this easier.

Lets implement a panel, which adds a "status-bar" below a sub-panel.

```nu
use potash/panel.nu panel_is_selectable
use potash/panel.nu panel_handle_input
use potash/panel.nu render_panel
use potash/panel.nu fix_string_width

def panel_with_status_bar [sub_panel, status_bar_content: string]: nothing -> record {{
  "T": "my_panel_with_status_bar",
  "data": {"sub_panel": $sub_panel, "status": $status_bar_content}
  "render": {|data,width,height,is_active| [
    ...(render_panel $data.sub_panel $width ($height - 2) $active)
    ("" | fill --character "-" --width $width)
    (fix_string_width $data.status $width)
  ]}
  "selectable": {|data| panel_is_selectable $data.sub_panel }
  "handle_input": {|data,input|
    let rv = (panel_handle_input $data.sub_panel $input)
    $rv
    | upsert data.sub_panel.data ($rv.data? | default $data.sub_panel.data)
  }
}}
```

the imported functions contain more direct implementations for the internal, which has multiple upsides:
* the implementation does not have to be attached as a closure to each instance
  * less RAM usage
  * less time spent cloning closure-objects
* they are faster (no `do`, etc)
* they can share code more efficiently

<a name="c3.4"></a>

## (3.4) Contribute to Internal / Builtin panels

Before spending work on this please considder if this should really be part of the standard-library.  
If you are unsure you can open up a Issue and ask.  
You can instead open up a library, which expands potash.

The builtin panels work slightly differently.  
To migrate a external one you will have to:

1. Copy the generator-function into the library.
2. move `render`, `selectable`, and `handle_input` into the `match` of `panel_is_selectable`, `render_panel`, and `panel_handle_input`. (copy the default case and fill in the closure)
3. move the code out of the closure (replace `$data` with `$panel.data`, etc)
4. document the function.
5. create a pull-request.

---

Chapter Overview: [index](./index.md)
