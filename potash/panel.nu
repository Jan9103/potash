export const UP_KEY_CODES = ["up", "w", "k"]
export const DOWN_KEY_CODES = ["down", "s", "j"]
export const LEFT_KEY_CODES = ["left", "a", "h"]
export const RIGHT_KEY_CODES = ["right", "d", "l"]

export const ANSI_ALT_BUFFER_OPEN = "\e[?1049h"
export const ANSI_ALT_BUFFER_CLOSE = "\e[?1049l"

export def panel_is_selectable [panel]: nothing -> bool {
  match $panel.T {
    "text" => false,
    "titled" => { panel_is_selectable $panel.data.panel }
    "hsplit" | "vsplit" | "vlist" => { $panel.data.panels | any {|subpanel| panel_is_selectable $subpanel } }
    "list_selector" | "inputline" | "checkbox" => true,
    _ => { if "selectable" in $panel { do $panel.selectable $panel.data } else { false } }
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
  match $panel.T {
    "text" | "titled" => {{}}
    "checkbox" => {
      return (if $input.code? in [" ", "enter"] { {
        "handled": true
        "data": ($panel.data | update active (not $panel.data.active))
      } } else { {} })
    }
    "vlist" => { split_handle_input $panel.data $input $DOWN_KEY_CODES $UP_KEY_CODES }
    "vsplit" => { split_handle_input $panel.data $input $DOWN_KEY_CODES $UP_KEY_CODES }
    "hsplit" => { split_handle_input $panel.data $input $RIGHT_KEY_CODES $LEFT_KEY_CODES }

    "titled" => {
      let rv = (panel_handle_input $panel.data.panel $input)
      if ("data" in $rv) {
        $rv | update data ($panel.data | update panel.data $rv.data)
      } else {$rv}
    }

    "list_selector" => {
      if $input.modifiers != [] or not ("code" in $input) {return {}}
      let new_data = (
        if $input.code in $DOWN_KEY_CODES {
          $panel.data
          | update selected ([($panel.data.selected + 1) (($panel.data.list | length) - 1)] | math min)
        } else if $input.code in $UP_KEY_CODES {
          $panel.data
          | update selected ([($panel.data.selected - 1) 0] | math max)
        } else {
          $panel.data
        }
      )
      let return_pressed: bool = ($input.code == "enter")
      {
        "data": $new_data
        "handled": (($panel.data.selected != $new_data.selected) or $return_pressed)
      }
      | merge (if $return_pressed {{"return": ($panel.data.list | get $panel.data.selected)}} else {{}})
    }

    "inputline" => {
      if $input.key_type? == "char" { return {
        "handled": true
        "data": (
          $panel.data | update "text" ([
            (if $panel.data.c == 0 {""} else {$panel.data.text | str substring --grapheme-clusters 0..($panel.data.c - 1)})
            $input.code
            (if $panel.data.c == ($panel.data.text | str length --grapheme-clusters) {""} else {$panel.data.text | str substring --grapheme-clusters ($panel.data.c)..})
          ] | str join '')
          | update "c" ($panel.data.c + 1)
        )
      } }
      if $input.code? == "backspace" and $panel.data.c != 0 { return {
        "handled": true
        "data": (
          $panel.data
          | update "text" ([
            (if $panel.data.c == 0 {""} else {$panel.data.text | str substring --grapheme-clusters 0..($panel.data.c - 2)})
            (if $panel.data.c == ($panel.data.text | str length --grapheme-clusters) {""} else {$panel.data.text | str substring --grapheme-clusters ($panel.data.c)..})
          ] | str join '')
          | update "c" ([0 ($panel.data.c - 1)] | math max)
        )
      } }
      if $input.modifiers? == [] and $input.code? == "left" and $panel.data.c != 0 { return {
        "handled": true
        "data": ($panel.data | update "c" ($panel.data.c - 1))
      } }
      if $input.modifiers? == [] and $input.code? == "right" and $panel.data.c < ($panel.data.text | str length --grapheme-clusters) { return {
        "handled": true
        "data": ($panel.data | update "c" ($panel.data.c + 1))
      } }
      return {"handled": false}
    }

    _ => {
      if "handle_input" in $panel {
        do $panel.handle_input $panel.data $input
      } else {{"handled": false}}
    }
  }
}

export def render_panel [panel, width: int, height: int, active: bool = true]: nothing -> list<string> {
  match $panel.T {
    "text" => {fix_size $panel.data.lines $width $height}
    "titled" => {[
      (fix_string_width $panel.data.title $width)
      (ansi reset | fill --character $panel.data.seperator --width $width)
      ...(render_panel $panel.data.panel $width ($height - 2) $active)
    ]}
    "checkbox" => {
      # TODO: color
      if $active {
        if $panel.data.active {
          fix_size [$'(ansi $panel.data.bas)[x](ansi reset) (ansi $panel.data.ta)($panel.data.text)'] $width $height
        } else {
          fix_size [$'(ansi $panel.data.bau)[ ](ansi reset) (ansi $panel.data.ta)($panel.data.text)'] $width $height
        }
      } else {
        if $panel.data.active {
          fix_size [$'(ansi $panel.data.bis)[x](ansi reset) (ansi $panel.data.ti)($panel.data.text)'] $width $height
        } else {
          fix_size [$'(ansi $panel.data.biu)[ ](ansi reset) (ansi $panel.data.ti)($panel.data.text)'] $width $height
        }
      }
    }

    "vlist" => {
      fix_size (
        $panel.data.panels | enumerate | each {|i|
          render_panel $i.item $width 1 ($active and ($i.index == $panel.data.selected))
        } | flatten
      ) $width $height
    }

    "vsplit" => {
      let pc: int = ($panel.data.panels | length)
      let vd: int = ((($height - $pc + 1) / $pc) | math floor)
      let vb: int = (($height - (($vd * $pc) + $pc - 1)) + $vd)
      let seperator: string = (ansi reset | fill --character $panel.data.seperator --width $width)
      $panel.data.panels | enumerate
      | each {|i| [(render_panel $i.item $width (if $i.index == 0 {$vb} else {$vd}) ($active and $i.index == $panel.data.selected)) $seperator] }
      | flatten | flatten | rangeslice 0..(-2)
    }

    "hsplit" => {
      let sw: int = ($panel.data.seperator | ansi strip | str length --grapheme-clusters)
      let pc: int = ($panel.data.panels | length)
      let hd: int = ((($width - (($pc - 1) * $sw)) / $pc) | math floor)
      let hb: int = (($width - (($hd * $pc) + (($pc - 1) * $sw))) + $hd)
      let seperator: string = $"(ansi reset)($panel.data.seperator)"
      let fd = (
        $panel.data.panels | enumerate
        | each {|i| render_panel $i.item (if $i.index == 0 {$hb} else {$hd}) $height ($active and $i.index == $panel.data.selected) }
      )
      0..($height - 1)
      | each {|line|
        $fd | each {|panel| $panel | get $line }
        | str join $seperator
      }
    }

    "list_selector" => {
      let scroll: int = ([($panel.data.selected - $height) ($panel.data.selected - 3) 0] | math max)
      let selected_ansi: string = (if $active {$panel.data.asa} else {$panel.data.sa})
      let unselected_ansi: string = (if $active {$panel.data.aua} else {$panel.data.ua})
      let namer = ($panel.data.namer | default {|item| $item | to nuon --raw})
      let lines: list<string> = (
        $panel.data.list
        | enumerate
        | rangeslice $scroll..($scroll + $height - 1)
        | each {|i| fix_string_width $"(if $i.index == $panel.data.selected {ansi $selected_ansi} else {ansi $unselected_ansi})(do $namer $i.item)" $width }
      )
      $lines
      | append (
        if $height <= ($lines | length) { [] } else {
          0..($height - ($lines | length) - 1)
          | each {"" | fill --width $width}
        }
      )
    }

    "inputline" => {
      # TODO: handle text wider than the field (scroll)
      let bg = (if $active {$panel.data.caa} else {$panel.data.cia})
      let ta = (if $panel.data.ta == "reset" {""} else {ansi $panel.data.ta})
      let text = ([
        $ta
        (if $panel.data.c == 0 {""} else {$panel.data.text | str substring --grapheme-clusters 0..($panel.data.c - 1)})
        $"(ansi $bg) (ansi reset)($ta)"
        (if $panel.data.c == ($panel.data.text | str length --grapheme-clusters) {""} else {$panel.data.text | str substring --grapheme-clusters ($panel.data.c + 1)..})
      ] | str join "")
      fix_size [$text] $width $height
    }

    _ => { do $panel.render $panel.data $width $height $active }
  }
}

export def fix_string_width [text: string, width: int]: nothing -> string {
  if $width <= 0 {return ""}
  let text = ($text | fill --width $width)
  mut i = ($width - 1)
  let tl = ($text | str length --grapheme-clusters)
  loop {
    let s = ($text | str substring --grapheme-clusters 0..$i)
    if ($s | ansi strip | str length --grapheme-clusters) == $width {
      return $s
    }
    $i = $i + 1
  }
  return ""  # impossible, but LSP
}

export def fix_size [lines: list<string>, width: int, height: int]: nothing -> list<string> {
  $lines
  | rangeslice 0..($height - 1)  # limit max height
  | each {|line| fix_string_width $line $width}
  | append (  # append empty lines
    if $height <= ($lines | length) { [] } else {
      0..($height - ($lines | length) - 1)
      | each {"" | fill --width $width}
    }
  )
}


# handle user input until the panel returns a value and return that.
# if the user presses `esc` it will return `null`
export def run_until_return [
  panel
  --no-esc  # do not handle `esc` as exit
]: nothing -> any {
  mut p0 = $panel
  print -n $ANSI_ALT_BUFFER_OPEN
  loop {
    let term_size = (term size)
    print -n (panel render_panel $p0 $term_size.columns $term_size.rows true | str join "\n")
    let inp = (input listen)
    if $inp.code? == "esc" and not $no_esc { print -n $ANSI_ALT_BUFFER_CLOSE; return null }
    let rv = (panel panel_handle_input $p0 $inp)
    if "data" in $rv { $p0 = ($p0 | update data ($rv.data)) }
    if "return" in $rv { print -n $ANSI_ALT_BUFFER_CLOSE; return $rv.return }
  }
}


#######################################
########## PANEL GENERATORS ###########
#######################################


# a panel, which display some static text
export def text [lines: list<string>]: nothing -> record {{
  "data": {"lines": $lines}
  "T": "text"
}}

export def checkbox [
  text: string,
  --active-by-default
  --box-active-selected-ansi: string = "green_reverse"
  --box-active-unselected-ansi: string = "red_reverse"
  --box-inactive-selected-ansi: string = "green"
  --box-inactive-unselected-ansi: string = "red"
  --text-active-ansi: string = "white_bold"
  --text-inactive-ansi: string = "white"
]: nothing -> record { {
  "data": {
    "text": $text, "active": $active_by_default
    "bas": $box_active_selected_ansi, "bau": $box_active_unselected_ansi
    "bis": $box_inactive_selected_ansi, "biu": $box_inactive_unselected_ansi
    "ta": $text_active_ansi, "ti": $text_inactive_ansi
  }
  "T": "checkbox"
} }

# vertically stack multiple 1 high panels without any seperation between them
export def vlist [
  ...panels
]: nothing -> record {
  mut selected: int = 0
  while $selected != (($panels | length) - 1) {
    if (panel_is_selectable ($panels | get $selected)) { break }
    $selected = ($selected + 1)
  }
  return {
    "data": {"panels": $panels, "selected": $selected}
    "T": "vlist"
  }
}

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
  return {
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
  return {
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
}}


# FIXME: crashes by rejecting $data.text.data.caa somehow
export def searchable_list_item_selector [
  --text-input-ansi: string = "reset"  # gets passed to 'inputline'
  --cursor-active-ansi: string = "bg_green"  # gets passed to 'inputline'
  --cursor-inactive-ansi: string = "bg_white"  # gets passed to 'inputline'
  --namer: any = null  # example: {|item| $item | to nuon --raw }
  --active-selected-ansi: string = "green_bold"  # gets passed to 'list_item_selector'
  --active-unselected-ansi: string = "reset"  # gets passed to 'list_item_selector'
  --selected-ansi: string = "white_bold"  # gets passed to 'list_item_selector'
  --unselected-ansi: string = "white"  # gets passed to 'list_item_selector'
  --seperator(-s): string = "─"  # other examples: ─ ━ ┄ ┅ ┈ ┉ ╌ ╍ ═ ╼ ╾
  input_list: list
] {{
  "T": "searchable_list_selector"
  "data": {
    "namer": $namer
    "raw_list": $input_list
    "seperator": $seperator
    "text": (inputline)
    "list": (list_item_selector $input_list --namer $namer --active-selected-ansi $active_selected_ansi --active-unselected-ansi $active_unselected_ansi --selected-ansi $selected_ansi --unselected-ansi $unselected_ansi)
  }
  "selectable": {|data| true}

  "render": {|data,width,height,active| [
    (render_panel $data.text $width 1 $active)
    (ansi reset | fill --character $data.seperator --width $width)
    ...(render_panel $data.list $width ($height - 2) $active)
  ]}

  "handle_input": {|data,input|
    let rv = (panel_handle_input $data.text $input)
    if "data" in $rv {
      let regex = $rv.data.text
      let filtered_list = (try {$data.raw_list | where (do $data.namer $it) =~ $regex} catch {[]})
      return (
        $rv | update data (
          $data
          | update list.data.list $filtered_list
          | update list.data.selected ([([$data.list.data.selected ($filtered_list | length)] | math min) 0] | math max)
          | updaet text.data $rv.data
        )
      )
    }

    let rv = (panel_handle_input $data.list $input)
    if "return" in $rv { return ($rv | reject data) }
    if "data" in $rv { return ($rv | update data ($data | update text.data $rv.data)) }
    return {}
  }
}}


export def inputline [
  --prefilled-text: string = ""
  --text-ansi: string = "reset"
  --cursor-active-ansi: string = "bg_green"
  --cursor-inactive-ansi: string = "bg_white"
] {{
  "T": "inputline"
  "data": {"text": $prefilled_text, "c": ($prefilled_text | str length --grapheme-clusters), "ta": $text_ansi, "caa": $cursor_active_ansi, "cia": $cursor_inactive_ansi}
}}

def rangeslice [a] {
  if (version).minor > 101 {
    $in | slice $a
  } else {
    $in | range $a
  }
}
