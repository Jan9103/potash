use ./potash/panel.nu

def main [
  items: list<any> = ["foo" "bar" "baz"]
]: nothing -> any {
  mut p0 = (
    panel vsplit
      (panel text ["top"])
      (panel hsplit
        (panel text ["center left"])
        (panel list_item_selector $items)
        (panel list_item_selector ["a" "b"]))
      (panel list_item_selector ["a" "b"])
  )
  loop {
    let tz = (term size)
    print -n (panel render_panel $p0 $tz.columns $tz.rows true | str join "\n")
    mut inp = (input listen)
    while not ("code" in $inp) {
      $inp = (input listen)
    }
    if $inp.code? == "esc" { return null }
    let rv = (panel panel_handle_input $p0 $inp)
    if "data" in $rv { $p0 = ($p0 | update data ($rv.data)) }
    if "return" in $rv {
      return $rv.return
    }
  }
}
