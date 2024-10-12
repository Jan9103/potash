use ./panel.nu


export def selector_panel_with_preview [
  items: list<any>
  preview_renderer  # example: {|item| $item | to nuon}
  name_renderer  # example: {|item| $item.name}
  --seperator(-s): string = " │ "  # other examples: │ ┃ ┆ ┇ ┊ ┋ ╎ ╏ ║ ╽ ╿
  --active-selected-ansi: string = "green_bold"
  --active-unselected-ansi: string = "reset"
  --selected-ansi: string = "white_bold"
  --unselected-ansi: string = "white"
]: nothing -> record {{
  "T": "selector_panel_with_preview"
  "data": {
    "panel": (
      panel hsplit --seperator $seperator
        (panel list_item_selector
          $items
          --namer $name_renderer
          --active-selected-ansi $active_selected_ansi
          --active-unselected-ansi $active_unselected_ansi
          --selected-ansi $selected_ansi
          --unselected-ansi $unselected_ansi
        )
        (panel text [])
    )
  }
  "selectable": {|| true}
  "handle_input": {|data,input|
    let p0 = $data.panel.data.panels.0
    let rv = (panel panel_handle_input $p0 $input)

    if "handled_input" in $rv {
      let new_text = (do $preview_renderer ($p0.list | get $p0.selected) | lines)
      $rv
      | upsert data (
        $data
        | update panel.data (
          $rv.data?
          | default $data.panel.data
          | upsert panels.1.data.lines $new_text
        )
      )
    } else {{}}
  }

  "render": {|data,width,height,active| panel render_panel $data.panel $width $height $active }
}}
