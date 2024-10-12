# (2) Builtin Panels

Chapter Overview: [index](./index.md)  
Previous Chapter: [Basics](./basics.md)  
Next chapter: [Creating own panel types](./own_panels.md)

* (2.1) [potash/panel.nu](#c2.1)
  * (2.1.1) [text](#c2.1.1)
  * (2.1.2) [hsplit](#c2.1.2)
  * (2.1.3) [vsplit](#c2.1.3)
  * (2.1.4) [titled](#c2.1.4)
  * (2.1.5) [list_item_selector](#c2.1.5)
* (2.2) [patash/advanced_panel.nu](#c2.2)
  * (2.2.1) [selector_panel_with_preview](#c2.2.1)

---

<a name="c2.1"></a>

## (2.1) potash/panel.nu

<a name="c2.1.1"></a>
<a name="_text"></a>

### text

A basic text panel. No line-wrapping.

Arguments:

* `lines: list<string>`

Data:

* `lines: list<string>`

<a name="c2.1.2"></a>
<a name="_hsplit"></a>

### hsplit

Split into multiple panels horizontally.

Keys:

* `left-arrow`, `a`, `h`: move panel-selection left (skips non-selectable)
* `right-arrow`, `d`, `l`: move panel-selection right (skips non-selectable)

Arguments:

* `--seperator: string`: The seperator text between the panels
  * Default: ` │ ` (with space characters on both sides)
  * Other nice characters: `│ ┃ ┆ ┇ ┊ ┋ ╎ ╏ ║ ╽ ╿`
* `...panels: Panel`

Data:

* `panels: list<Panel>`
* `selected: int`
* `sperator: string`

<a name="c2.1.3"></a>
<a name="_vsplit"></a>

### vsplit

Split into multiple panels vertically.

Keys:

* `up-arrow`, `w`, `k`: move panel-selection up (skips non-selectable)
* `down-arrow`, `s`, `j`: move panel-selection down (skips non-selectable)

Arguments:

* `--seperator: string`: The seperator character between the panels
  * Default: `─`
  * Other nice characters: `─ ━ ┄ ┅ ┈ ┉ ╌ ╍ ═ ╼ ╾`
* `...panels: Panel`

Data:

* `panels: list<Panel>`
* `selected: int`
* `sperator: string`

<a name="c2.1.4"></a>
<a name="_titled"></a>

### titled

Add a title-line + seperator above a panel

Arguments:

* `--seperator: string`: The seperator between the title and the panel
  * Default: `─`
  * Other nice characters: `─ ━ ┄ ┅ ┈ ┉ ╌ ╍ ═ ╼ ╾`
* `...panels: Panel`

Data:

* `panel: Panel`
* `title: string`
* `seperator: string`

<a name="c2.1.5"></a>
<a name="_list_item_selector"></a>

### list_item_selector

A panel displaying a list of items allowing the user to select a entry and confirm it with `return`.

Keys:

* modifiers (`shift`, `crtl`, etc) disable it. this makes it possible to pass `shift+down` to a parent `vsplit`.
* `return`: confirm selection
* `down-arrow`, `s`, `j`: move selection down
* `up-arrow`, `w`, `k`: move selection up

Arguments:

* `--namer: closure`: A function, which gives a entry a name
  * Default: `{|item| $item | to nuon --raw}`
  * Another usage idea: `{|file| open --raw $file.name | lines | get 0}`
* `--active-selected-ansi: string`: `ansi` argument for the selected entry when the panel is active
  * Default: `green_bold`
  * Also good option: `green_reverse`
* `--active-unselected-ansi: string`: `ansi` argument for the unselected entries when the panel is active
  * Default: `reset`
* `--selected-ansi: string`: `ansi` argument for the selected entry when the panel is inactive
  * Default: `white_bold`
* `--unselected-ansi: string`: `ansi` argument for the unselected entries when the panel is inactive
  * Default: `white`
* `input_list: list<any>`: the items available to choose from

Data:

* `list: list<any>`
* `selected: int`
* `namer: closure`
* ansi codes: the initials (ex: `aua`) of the arguments.

---

<a name="c2.2"></a>

## (2.2) potash/advanced_panel.nu

<a name="c2.2.1"></a>

### (2.2.1) selector_panel_with_preview

A dual-panel with a item-list on the left and a preview on the right.

Keys: same as `item_list`

Arguments:

* `items: list<any>`: The items to choose from
* `preview_renderer: closure`: code to generate a preview based on the item
  * Examples: `{|item| $item | to nuon}`, `|items| open --raw $item}`
* `name_renderer: closure`: code to generate a name for a item
  * Examples: `{|item| $item.name}`, `{|item| $item | to nuon --raw}`
* `--seperator: string` (passed to [hsplit](#_hsplit))
* all `ansi` options from [list_item_selector](#_list_item_selector)

Data:

* `panel: HsplitPanel<ListItemSelectorPanel, TextPanel>`

---

Chapter Overview: [index](./index.md)  
Next chapter: [Creating own panel types](./own_panels.md)
