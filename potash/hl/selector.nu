use ../advanced_panel.nu selector_panel_with_preview
use ../panel.nu run_until_return

export def choose_with_preview [
  --preview-renderer(-p): any  # default: {|item| $item | to nuon}
  --name-renderer(-n): any  # default: {|item| $item | to nuon --raw}
  --seperator: string = " │ "  # other examples: │ ┃ ┆ ┇ ┊ ┋ ╎ ╏ ║ ╽ ╿
  --selected-ansi: string = "green_bold"  # the `ansi` argument for tne selected item
  --unselected-ansi: string = "reset"  # the `ansi` argument for the unselected items
]: list<any> -> any {
  let items: list<any> = $in
  run_until_return (
    selector_panel_with_preview
      $in
      ($preview_renderer | default {|item| $item | to nuon})
      ($name_renderer | default {|item| $item | to nuon --raw})
      --active-selected-ansi $selected_ansi
      --active-unselected-ansi $unselected_ansi
      --seperator $seperator
  )
}
