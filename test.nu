use potash/panel.nu
# use potash/input.nu textfield_panel

def main [] {
  # panel render_panel (textfield_panel) 50 1
  # | str join "\n"
  panel dual_until_return (panel text ["hi"]) --render-task {|panel| {"data": {"lines": [(random uuid)]}}}
}
