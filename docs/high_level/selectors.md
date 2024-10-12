#  potash/hl/selector.nu

## choose_with_preview

Let the user choose a item from a list and provide them with a preview.

Example:

```nu
use potash/hl/selector.nu choose_with_preview

let chosen_file = (
  ls | get name | choose_with_preview --preview_renderer {|item| open --raw $item}
)
if $chosen_file != null {
  rm -rf $chosen_file
}
```

Arguments:
* `--preview-renderer(-p): closure`: a function providing the preview-text.
  * Default: `{|item| $item | to nuon}`
* `--name-renderer(-n): closure`: a function providing the item name for the list.
  * Default: `{|item| $item | to nuon --raw}`
* `--seperator: string`: The seperator text to render between the item-list and preview.
  * Default: ` │ ` (with a space on each side)
  * Other unicode characters for copy-and-paste: `│ ┃ ┆ ┇ ┊ ┋ ╎ ╏ ║ ╽ ╿`
* `--selected-ansi`: the `ansi`-command argument for the selected list item.
  * Default: `green_bold`
  * Alternative recommendation: `green_reverse`
  * List of options: `ansi -l`
* `--unselected-ansi`: the `ansi`-command argument for the unselected list items.
  * Default: `reset` (default color)
  * List of options: `ansi -l`


