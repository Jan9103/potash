const UP_KEY_CODES = ["up", "w", "k"]
const DOWN_KEY_CODES = ["down", "s", "j"]
const LEFT_KEY_CODES = ["left", "a", "h"]
const RIGHT_KEY_CODES = ["right", "d", "l"]

export def panel_is_selectable [panel]: nothing -> bool {
  match $panel.T {
    "text" => false,
    "titled" => { panel_is_selectable $panel.data.panel }
    "vsplit" => { $panel.data.panels | any {|subpanel| panel_is_selectable $subpanel } }
    "hsplit" => { $panel.data.panels | any {|subpanel| panel_is_selectable $subpanel } }
    _ => { if "selectable" in $panel { do $panel.selectable } else { false } }
  }
}

def split_handle_input [data, input, plus_keys, minus_keys]: nothing -> record {
  let subpanel = ($data.panels | get $data.selected)
  let rv = (panel_handle_input $subpanel $input)
  let subpanels = (if ("data" in $rv) {$data.panels | update $data.selected (($data.panels | get $data.selected) | update data $rv.data)} else {$data.panels})
  let new_selected: int = (if $rv.handled? == true {$data.selected} else {
      if ($data.selected != 0 and $input.code? in $minus_keys) {
        mut i = $data.selected - 1
        while $i != -1 {
          if (panel_is_selectable ($data.panels | get $i)) { break }
          $i = ($i - 1)
        }
        if $i == -1 { $data.selected } else { $i }
      } else if ($input.code? in $plus_keys and ($data.selected + 1) < ($data.panels | length)) {
        mut i = $data.selected + 1
        while $i != ($data.panels | length) {
          if (panel_is_selectable ($data.panels | get $i)) { break }
          $i = ($i + 1)
        }
        if $i == ($data.panels | length) { $data.selected } else { $i }
      } else { $data.selected }
  })
  $rv
  | upsert handled (($rv.handled? == true) or ($new_selected != $data.selected))
  | upsert data (
    $data
    | update selected $new_selected
    | update panels $subpanels
  )
}

export def panel_handle_input [panel, input]: nothing -> record {
  let handler = (match $panel.T {
    "text" => {{|data,input| {"handled": "false"}}}
    "titled" => {{|data,input| {"handled": "false"}}}
    "vsplit" => {{|data,input| split_handle_input $data $input $DOWN_KEY_CODES $UP_KEY_CODES }}
    "hsplit" => {{|data,input| split_handle_input $data $input $RIGHT_KEY_CODES $LEFT_KEY_CODES }}
    _ => {$panel.handle_input? | default {|data,input| {}}}
  })
  do $handler $panel.data $input
}

export def render_panel [panel, width: int, height: int, active: bool]: nothing -> list<string> {
  let renderer = (match $panel.T {
    "text" => {{|data,width,height,active| fix_size $data.lines $width $height}}
    "generator" => {{|data,width,height,active| do $data.code? $width $height}}
    "titled" => {{|data,width,height,active| [
      (fix_string_width $data.title $width)
      (ansi reset | fill --character $data.seperator --width $width)
      ...(render_panel $data.panel $width ($height - 2) $active)
    ] }}

    "vsplit" => {{|data,width,height,active|
      let pc: int = ($data.panels | length)
      let vd: int = ((($height - $pc + 1) / $pc) | math floor)
      let vb: int = (($height - (($vd * $pc) + $pc - 1)) + $vd)
      let seperator: string = (ansi reset | fill --character $data.seperator --width $width)
      $data.panels | enumerate
      | each {|i| [(render_panel $i.item $width (if $i.index == 0 {$vb} else {$vd}) ($active and $i.index == $data.selected)) $seperator] }
      | flatten | flatten | range 0..(-2)
    }}

    "hsplit" => {{|data,width,height,active|
      let sw: int = ($data.seperator | ansi strip | str length --grapheme-clusters)
      let pc: int = ($data.panels | length)
      let hd: int = ((($width - (($pc - 1) * $sw)) / $pc) | math floor)
      let hb: int = (($width - (($hd * $pc) + (($pc - 1) * $sw))) + $hd)
      let seperator: string = $"(ansi reset)($data.seperator)"
      let fd = (
        $data.panels | enumerate
        | each {|i| render_panel $i.item (if $i.index == 0 {$hb} else {$hd}) $height ($active and $i.index == $data.selected) }
      )
      0..($height - 1)
      | each {|line|
        $fd | each {|panel| $panel | get $line }
        | str join $seperator
      }
    }}

    _ => $panel.render
  })
  do $renderer $panel.data $width $height $active
}

def fix_string_width [text: string, width: int]: nothing -> string {
  if $width <= 0 {return ""}
  let text = ($text | fill --width $width)
  mut i = $width
  let tl = ($text | str length --grapheme-clusters)
  loop {
    let s = ($text | str substring --grapheme-clusters 0..($i - 1))
    if ($s | ansi strip | str length --grapheme-clusters) == $width {
      return $s
    }
    $i = $i + 1
  }
  return ""  # impossible, but LSP
}

export def fix_size [lines: list<string>, width: int, height: int]: nothing -> list<string> {
  $lines
  | range 0..($height - 1)  # limit max height
  | each {|line| fix_string_width $line $width}
  | append (
    if $height <= ($lines | length) { [] } else {
      0..($height - ($lines | length) - 1)
      | each {"" | fill --width $width}
    }
  )
}

# a panel, which display some static text
export def text [lines: list<string>]: nothing -> record {{
  "data": {"lines": $lines}
  "T": "text"
}}

# a generator panel, whichs contents you can generate
export def generator [
  code  # example: {|width,height| panel fix_size (date now | into string) $width $height}
]: nothing -> record {{
  "data": {"code": $code}
  "T": "generator"
}}

# a panel, which splits multiple panels vertically
export def vsplit [
  --seperator(-s): string = "─"  # other examples: ─ ━ ┄ ┅ ┈ ┉ ╌ ╍ ═ ╼ ╾
  ...panels
]: nothing -> record {
  mut selected: int = 0
  while $selected != (($panels | length) - 1) {
    if (panel_is_selectable ($panels | get $selected)) { break }
    $selected = ($selected + 1)
  }
  {
    "data": {"panels": $panels, "seperator": $seperator, "selected": $selected}
    "T": "vsplit"
  }
}

# a panel, which splits multiple panels horizontally
export def hsplit [
  --seperator(-s): string = " │ "  # other examples: │ ┃ ┆ ┇ ┊ ┋ ╎ ╏ ║ ╽ ╿
  ...panels
]: nothing -> record {
  mut selected: int = 0
  while $selected != (($panels | length) - 1) {
    if (panel_is_selectable ($panels | get $selected)) { break }
    $selected = ($selected + 1)
  }
  {
    "data": {"panels": $panels, "seperator": $seperator, "selected": $selected}
    "T": "hsplit"
  }
}

export def titled [
  --seperator(-s): string = "─"  # other examples: ─ ━ ┄ ┅ ┈ ┉ ╌ ╍ ═ ╼ ╾
  title: string
  panel
] {{
  "data": {"title": $title, "panel": $panel, "seperator": $seperator}
  "T": "titled"
}}


export def list_item_selector [
  --namer: any = null  # example: {|item| $item | to nuon --raw }
  --active-selected-ansi: string = "green_bold"
  --active-unselected-ansi: string = "reset"
  --selected-ansi: string = "white_bold"
  --unselected-ansi: string = "white"
  input_list: list
] {{
  "data": {"list": $input_list, "selected": 0, "namer": $namer, "asa": $active_selected_ansi, "aua": $active_unselected_ansi, "sa": $selected_ansi, "ua": $unselected_ansi}
  "T": "list_selector"
  "render": {|data,width,height,active|
    let scroll: int = ([($data.selected - $height) ($data.selected - 3) 0] | math max)
    let selected_ansi: string = (if $active {$data.asa} else {$data.sa})
    let unselected_ansi: string = (if $active {$data.aua} else {$data.ua})
    let namer = ($data.namer | default {|item| $item | to nuon --raw})
    let lines: list<string> = (
      $data.list
      | enumerate
      | range $scroll..($scroll + $height - 1)
      | each {|i|
        fix_string_width $"(if $i.index == $data.selected {ansi $selected_ansi} else {ansi $unselected_ansi})(do $namer $i.item)" $width
      }
    )
    $lines
    | append (
      if $height <= ($lines | length) { [] } else {
        0..($height - ($lines | length) - 1)
        | each {"" | fill --width $width}
      }
    )
  }
  "selectable": {|| true}
  "handle_input": {|data,input|
    let new_data = (
      if $input.modifiers != [] {
        $data
      } else if $input.code? in $DOWN_KEY_CODES {
        $data
        | update selected ([($data.selected + 1) (($data.list | length) - 1)] | math min)
      } else if $input.code? in $UP_KEY_CODES {
        $data
        | update selected ([($data.selected - 1) 0] | math max)
      } else {
        $data
      }
    )
    let return_pressed: bool = ($input.code? in ["enter"])
    {
      "data": $new_data
      "handled": (($data.selected != $new_data.selected) or $return_pressed)
    }
    | merge (if $return_pressed {{"return": ($data.list | get $data.selected)}} else {{}})
  }
}}
