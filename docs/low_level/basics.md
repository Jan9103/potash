# (1) Low level API: Basics

Chapter Overview: [index](./index.md)  
Next chapter: [Builtin Panels](./builtin_panels.md)

* (1.1) [Panels](#c1.1)
* (1.2) [Splits](#c1.2)
* (1.3) [Example wrapper code](#c1.3)
  * (1.3.1) [Data-only panel](#c1.3.1)
  * (1.3.2) [Interactive panel](#c1.3.2)

---

<a name="c1.1"></a>

## (1.1) Panels

Everything in potash is a panel.  
Every panel implements among other things a function, which will render graphics for the provided size and width.

Example:
```
$ use ./potash/panel.nu

$ panel text --help
panel text <lines of text>

$ panel render --help
panel render <panel> <width> <height> <is_active>

$ panel render (panel text ["hi"]) 2 1 true | str join "\n"
hi
```

<a name="c1.2"></a>

## (1.2) Splits

In order to render multiple panels at once you can use `hsplit` (horizontal split) and `vsplit`
panels, which can contain multiple panels and will render those.

Example:
```
$ use ./potash/panel.nu

$ panel hsplit --help
panel hsplit <...panels>

$ panel render (panel hsplit (panel text ["hi"]) (panel text ["hi"])) 7 1 true | str join "\n"
hi │ hi

$ panel render (panel vsplit (panel text ["hi"]) (panel text ["hi"])) 7 1 true | str join "\n"
hi
──
hi
```

<a name="c1.3"></a>

## (1.3) Example wrapper code

<a name="c1.3.1"></a>

### (1.3.1) Data-only panel

```nu
mut p0 = (panel hsplit (panel text ["Left"]) (panel text ["right"]))

loop {
  # RENDER THE UI
  let term_size = (term size)
  print -n (panel render_panel $p0 $term_size.columns $term_size.rows true | str join "\n")

  # UPDATE THE DATA DISPLAYED
  # in this example we just randomize the contents of the left panel each frame,
  # but you could easily fill in CPU-usage statistics, log-messages, or similar
  $p0 = (
    $p0
    | update data.panels.0.data.text (random uuid)
  )

  # WAIT BETWEEN REDRAWS
  # why?
  # * high refresh rates can cause flickering depending on the terminal used.
  #   GPU-accelerated terminals, like wezterm and alacritty, are generally fine,
  #   but other terminals like urxvt start flickering pretty quickly.
  # * how would anyone read anything if the numers update constantly.
  # * why put unnecesary load on the cpu? this isn't a 3D AAA-game with great graphics.
  sleep 0.25sec
}
```


<a name="c1.3.2"></a>

### (1.3.2) Interactive panel

```nu
use potash/panel.nu

def select_item [list: list<any>]: nothing -> any {
  # SETUP
  # The base panel (this could also be a more complex one with subpanels, etc)
  mut p0 = (panel list_item_selector $list)

  loop {
    # RENDER THE UI
    let term_size = (term size)
    print -n (panel render_panel $p0 $term_size.columns $term_size.rows true | str join "\n")

    # GET USER-INPUT
    # `let inp = (input listen)` would be enough, but ignoring mouse-inputs
    # reduceses refresh-rate and therefore reduces flickering
    let inp = (input listen --types ["resize", "key"])
    if $inp.type == "resize" { continue }

    # ESCAPE KEY IMPLEMENTATION
    # you could also move this below `let rv` and only handle it if
    # no panel has handled it beforehand
    if $inp.code? == "esc" { return null }

    # LET PANEL HANDLE KEY-INPUTS
    let rv = (panel panel_handle_input $p0 $inp)
    # handle panel-data updates
    if "data" in $rv { $p0 = ($p0 | update data ($rv.data)) }
    # handle panel-return values (in this case the confirmation of a selection)
    if "return" in $rv { return $rv.return }
  }
}

select_item (ls | get name)
```

A basic handle userinput until return is also available at `potash/panel.nu run_until_return`.

---

Chapter Overview: [index](./index.md)  
Next chapter: [Builtin Panels](./builtin_panels.md)
