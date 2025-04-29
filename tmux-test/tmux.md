| Key Table | Repeatable | Key | Command |
| :------------ | :--------- | :------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| copy-mode | | Escape | send-keys -X cancel |
| copy-mode | | Space | send-keys -X page-down |
| copy-mode | | ! | send-keys -X copy-pipe-and-cancel "tr -d '\n' | wl-copy" |
| copy-mode | | , | send-keys -X jump-reverse |
| copy-mode | | ; | send-keys -X jump-again |
| copy-mode | | F | command-prompt -1 -p "(jump backward)" { send-keys -X jump-backward "%%" } |
| copy-mode | | N | send-keys -X search-reverse |
| copy-mode | | P | send-keys -X toggle-position |
| copy-mode | | R | send-keys -X rectangle-toggle |
| copy-mode | | T | command-prompt -1 -p "(jump to backward)" { send-keys -X jump-to-backward "%%" } |
| copy-mode | | X | send-keys -X set-mark |
| copy-mode | | Y | send-keys -X copy-pipe-and-cancel "tmux paste-buffer -p" |
| copy-mode | | f | command-prompt -1 -p "(jump forward)" { send-keys -X jump-forward "%%" } |
| copy-mode | | g | command-prompt -p "(goto line)" { send-keys -X goto-line "%%" } |
| copy-mode | | n | send-keys -X search-again |
| copy-mode | | q | send-keys -X cancel |
| copy-mode | | r | send-keys -X refresh-from-pane |
| copy-mode | | t | command-prompt -1 -p "(jump to forward)" { send-keys -X jump-to-forward "%%" } |
| copy-mode | | y | send-keys -X copy-pipe-and-cancel wl-copy |
| copy-mode | | MouseDown1Pane | select-pane |
| copy-mode | | MouseDrag1Pane | select-pane \; send-keys -X begin-selection |
| copy-mode | | MouseDragEnd1Pane | send-keys -X copy-pipe-and-cancel wl-copy |
| copy-mode | | WheelUpPane | select-pane \; send-keys -X -N 5 scroll-up |
| copy-mode | | WheelDownPane | select-pane \; send-keys -X -N 5 scroll-down |
| copy-mode | | DoubleClick1Pane | select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel |
| copy-mode | | TripleClick1Pane | select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel |
| copy-mode | | Home | send-keys -X start-of-line |
| copy-mode | | End | send-keys -X end-of-line |
| copy-mode | | NPage | send-keys -X page-down |
| copy-mode | | PPage | send-keys -X page-up |
| copy-mode | | Up | send-keys -X cursor-up |
| copy-mode | | Down | send-keys -X cursor-down |
| copy-mode | | Left | send-keys -X cursor-left |
| copy-mode | | Right | send-keys -X cursor-right |
| copy-mode | | M-1 | command-prompt -N -I 1 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-2 | command-prompt -N -I 2 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-3 | command-prompt -N -I 3 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-4 | command-prompt -N -I 4 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-5 | command-prompt -N -I 5 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-6 | command-prompt -N -I 6 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-7 | command-prompt -N -I 7 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-8 | command-prompt -N -I 8 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-9 | command-prompt -N -I 9 -p (repeat) { send-keys -N "%%" } |
| copy-mode | | M-< | send-keys -X history-top |
| copy-mode | | M-> | send-keys -X history-bottom |
| copy-mode | | M-R | send-keys -X top-line |
| copy-mode | | M-b | send-keys -X previous-word |
| copy-mode | | M-f | send-keys -X next-word-end |
| copy-mode | | M-m | send-keys -X back-to-indentation |
| copy-mode | | M-r | send-keys -X middle-line |
| copy-mode | | M-v | send-keys -X page-up |
| copy-mode | | M-w | send-keys -X copy-pipe-and-cancel |
| copy-mode | | M-x | send-keys -X jump-to-mark |
| copy-mode | | M-y | send-keys -X copy-pipe-and-cancel "wl-copy; tmux paste-buffer -p" |
| copy-mode | | M-{ | send-keys -X previous-paragraph |
| copy-mode | | M-} | send-keys -X next-paragraph |
| copy-mode | | M-Up | send-keys -X halfpage-up |
| copy-mode | | M-Down | send-keys -X halfpage-down |
| copy-mode | | C-Space | send-keys -X begin-selection |
| copy-mode | | C-a | send-keys -X start-of-line |
| copy-mode | | C-b | send-keys -X cursor-left |
| copy-mode | | C-c | send-keys -X cancel |
| copy-mode | | C-e | send-keys -X end-of-line |
| copy-mode | | C-f | send-keys -X cursor-right |
| copy-mode | | C-g | send-keys -X clear-selection |
| copy-mode | | C-k | send-keys -X copy-pipe-end-of-line-and-cancel |
| copy-mode | | C-n | send-keys -X cursor-down |
| copy-mode | | C-p | send-keys -X cursor-up |
| copy-mode | | C-r | command-prompt -i -I "#{pane_search_string}" -T search -p "(search up)" { send-keys -X search-backward-incremental "%%" } |
| copy-mode | | C-s | command-prompt -i -I "#{pane_search_string}" -T search -p "(search down)" { send-keys -X search-forward-incremental "%%" } |
| copy-mode | | C-v | send-keys -X page-down |
| copy-mode | | C-w | send-keys -X copy-pipe-and-cancel |
| copy-mode | | C-Up | send-keys -X scroll-up |
| copy-mode | | C-Down | send-keys -X scroll-down |
| copy-mode | | C-M-b | send-keys -X previous-matching-bracket |
| copy-mode | | C-M-f | send-keys -X next-matching-bracket |
| copy-mode-vi | | Enter | send-keys -X copy-pipe-and-cancel |
| copy-mode-vi | | Escape | send-keys -X clear-selection |
| copy-mode-vi | | Space | send-keys -X begin-selection |
| copy-mode-vi | | ! | send-keys -X copy-pipe-and-cancel "tr -d '\n' | wl-copy" |
| copy-mode-vi | | # | send-keys -FX search-backward "#{copy_cursor_word}" |
| copy-mode-vi | | $ | send-keys -X end-of-line |
| copy-mode-vi | | % | send-keys -X next-matching-bracket |
| copy-mode-vi | | * | send-keys -FX search-forward "#{copy_cursor_word}" |
| copy-mode-vi | | , | send-keys -X jump-reverse |
| copy-mode-vi | | / | command-prompt -T search -p "(search down)" { send-keys -X search-forward "%%" } |
| copy-mode-vi | | 0 | send-keys -X start-of-line |
| copy-mode-vi | | 1 | command-prompt -N -I 1 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 2 | command-prompt -N -I 2 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 3 | command-prompt -N -I 3 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 4 | command-prompt -N -I 4 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 5 | command-prompt -N -I 5 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 6 | command-prompt -N -I 6 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 7 | command-prompt -N -I 7 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 8 | command-prompt -N -I 8 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | 9 | command-prompt -N -I 9 -p (repeat) { send-keys -N "%%" } |
| copy-mode-vi | | : | command-prompt -p "(goto line)" { send-keys -X goto-line "%%" } |
| copy-mode-vi | | ; | send-keys -X jump-again |
| copy-mode-vi | | ? | command-prompt -T search -p "(search up)" { send-keys -X search-backward "%%" } |
| copy-mode-vi | | A | send-keys -X append-selection-and-cancel |
| copy-mode-vi | | B | send-keys -X previous-space |
| copy-mode-vi | | D | send-keys -X copy-pipe-end-of-line-and-cancel |
| copy-mode-vi | | E | send-keys -X next-space-end |
| copy-mode-vi | | F | command-prompt -1 -p "(jump backward)" { send-keys -X jump-backward "%%" } |
| copy-mode-vi | | G | send-keys -X history-bottom |
| copy-mode-vi | | H | send-keys -X top-line |
| copy-mode-vi | | J | send-keys -X scroll-down |
| copy-mode-vi | | K | send-keys -X scroll-up |
| copy-mode-vi | | L | send-keys -X bottom-line |
| copy-mode-vi | | M | send-keys -X middle-line |
| copy-mode-vi | | N | send-keys -X search-reverse |
| copy-mode-vi | | P | send-keys -X toggle-position |
| copy-mode-vi | | T | command-prompt -1 -p "(jump to backward)" { send-keys -X jump-to-backward "%%" } |
| copy-mode-vi | | V | send-keys -X select-line |
| copy-mode-vi | | W | send-keys -X next-space |
| copy-mode-vi | | X | send-keys -X set-mark |
| copy-mode-vi | | Y | send-keys -X copy-pipe-and-cancel "tmux paste-buffer -p" |
| copy-mode-vi | | ^ | send-keys -X back-to-indentation |
| copy-mode-vi | | b | send-keys -X previous-word |
| copy-mode-vi | | e | send-keys -X next-word-end |
| copy-mode-vi | | f | command-prompt -1 -p "(jump forward)" { send-keys -X jump-forward "%%" } |
| copy-mode-vi | | g | send-keys -X history-top |
| copy-mode-vi | | h | send-keys -X cursor-left |
| copy-mode-vi | | j | send-keys -X cursor-down |
| copy-mode-vi | | k | send-keys -X cursor-up |
| copy-mode-vi | | l | send-keys -X cursor-right |
| copy-mode-vi | | n | send-keys -X search-again |
| copy-mode-vi | | o | send-keys -X other-end |
| copy-mode-vi | | q | send-keys -X cancel |
| copy-mode-vi | | r | send-keys -X refresh-from-pane |
| copy-mode-vi | | t | command-prompt -1 -p "(jump to forward)" { send-keys -X jump-to-forward "%%" } |
| copy-mode-vi | | v | send-keys -X rectangle-toggle |
| copy-mode-vi | | w | send-keys -X next-word |
| copy-mode-vi | | y | send-keys -X copy-pipe-and-cancel wl-copy |
| copy-mode-vi | | z | send-keys -X scroll-middle |
| copy-mode-vi | | { | send-keys -X previous-paragraph |
| copy-mode-vi | | } | send-keys -X next-paragraph |
| copy-mode-vi | | MouseDown1Pane | select-pane |
| copy-mode-vi | | MouseDrag1Pane | select-pane \; send-keys -X begin-selection |
| copy-mode-vi | | MouseDragEnd1Pane | send-keys -X copy-pipe-and-cancel wl-copy |
| copy-mode-vi | | WheelUpPane | select-pane \; send-keys -X -N 5 scroll-up |
| copy-mode-vi | | WheelDownPane | select-pane \; send-keys -X -N 5 scroll-down |
| copy-mode-vi | | DoubleClick1Pane | select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel |
| copy-mode-vi | | TripleClick1Pane | select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel |
| copy-mode-vi | | BSpace | send-keys -X cursor-left |
| copy-mode-vi | | Home | send-keys -X start-of-line |
| copy-mode-vi | | End | send-keys -X end-of-line |
| copy-mode-vi | | NPage | send-keys -X page-down |
| copy-mode-vi | | PPage | send-keys -X page-up |
| copy-mode-vi | | Up | send-keys -X cursor-up |
| copy-mode-vi | | Down | send-keys -X cursor-down |
| copy-mode-vi | | Left | send-keys -X cursor-left |
| copy-mode-vi | | Right | send-keys -X cursor-right |
| copy-mode-vi | | M-x | send-keys -X jump-to-mark |
| copy-mode-vi | | M-y | send-keys -X copy-pipe-and-cancel "wl-copy; tmux paste-buffer -p" |
| copy-mode-vi | | C-b | send-keys -X page-up |
| copy-mode-vi | | C-c | send-keys -X cancel |
| copy-mode-vi | | C-d | send-keys -X halfpage-down |
| copy-mode-vi | | C-e | send-keys -X scroll-down |
| copy-mode-vi | | C-f | send-keys -X page-down |
| copy-mode-vi | | C-h | send-keys -X cursor-left |
| copy-mode-vi | | C-j | send-keys -X copy-pipe-and-cancel |
| copy-mode-vi | | C-u | send-keys -X halfpage-up |
| copy-mode-vi | | C-v | send-keys -X rectangle-toggle |
| copy-mode-vi | | C-y | send-keys -X scroll-up |
| copy-mode-vi | | C-Up | send-keys -X scroll-up |
| copy-mode-vi | | C-Down | send-keys -X scroll-down |
| prefix | | Space | next-layout |
| prefix | | ! | break-pane |
| prefix | | " | split-window |
| prefix | | # | list-buffers |
| prefix | | $ | command-prompt -I "#S" { rename-session "%%" } |
| prefix | | % | split-window -h |
| prefix | | & | confirm-before -p "kill-window #W? (y/n)" kill-window |
| prefix | | ' | command-prompt -T window-target -p index { select-window -t ":%%" } |
| prefix | | ( | switch-client -p |
| prefix | | ) | switch-client -n |
| prefix | | , | command-prompt -I "#W" { rename-window "%%" } |
| prefix | | - | delete-buffer |
| prefix | | . | command-prompt -T target { move-window -t "%%" } |
| prefix | | / | command-prompt -k -p key { list-keys -1N "%%" } |
| prefix | | 0 | select-window -t :=0 |
| prefix | | 1 | select-window -t :=1 |
| prefix | | 2 | select-window -t :=2 |
| prefix | | 3 | select-window -t :=3 |
| prefix | | 4 | select-window -t :=4 |
| prefix | | 5 | select-window -t :=5 |
| prefix | | 6 | select-window -t :=6 |
| prefix | | 7 | select-window -t :=7 |
| prefix | | 8 | select-window -t :=8 |
| prefix | | 9 | select-window -t :=9 |
| prefix | | : | command-prompt |
| prefix | | ; | last-pane |
| prefix | | < | display-menu -T "#[align=centre]#{window_index}:#{window_name}" -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window } |
| prefix | | = | choose-buffer -Z |
| prefix | | > | display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -x P -y P "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } |
| prefix | | ? | list-keys -N |
| prefix | | C | customize-mode -Z |
| prefix | | D | choose-client -Z |
| prefix | | E | select-layout -E |
| prefix | | I | run-shell /home/mz/.tmux/plugins/tpm/bindings/install_plugins |
| prefix | | L | switch-client -l |
| prefix | | M | select-pane -M |
| prefix | | U | run-shell /home/mz/.tmux/plugins/tpm/bindings/update_plugins |
| prefix | | Y | run-shell -b /home/mz/.tmux/plugins/tmux-yank/scripts/copy_pane_pwd.sh |
| prefix | | [ | copy-mode |
| prefix | | ] | paste-buffer -p |
| prefix | | c | new-window |
| prefix | | d | detach-client |
| prefix | | f | command-prompt { find-window -Z "%%" } |
| prefix | | i | display-message |
| prefix | | l | last-window |
| prefix | | m | select-pane -m |
| prefix | | n | next-window |
| prefix | | o | select-pane -t :.+ |
| prefix | | p | previous-window |
| prefix | | q | display-panes |
| prefix | | r | refresh-client |
| prefix | | s | choose-tree -Zs |
| prefix | | t | clock-mode |
| prefix | | w | choose-tree -Zw |
| prefix | | x | confirm-before -p "kill-pane #P? (y/n)" kill-pane |
| prefix | | y | run-shell -b /home/mz/.tmux/plugins/tmux-yank/scripts/copy_line.sh |
| prefix | | z | resize-pane -Z |
| prefix | | { | swap-pane -U |
| prefix | | } | swap-pane -D |
| prefix | | ~ | show-messages |
| prefix | Yes | DC | refresh-client -c |
| prefix | | PPage | copy-mode -u |
| prefix | Yes | Up | select-pane -U |
| prefix | Yes | Down | select-pane -D |
| prefix | Yes | Left | select-pane -L |
| prefix | Yes | Right | select-pane -R |
| prefix | | M-1 | select-layout even-horizontal |
| prefix | | M-2 | select-layout even-vertical |
| prefix | | M-3 | select-layout main-horizontal |
| prefix | | M-4 | select-layout main-vertical |
| prefix | | M-5 | select-layout tiled |
| prefix | | M-6 | select-layout main-horizontal-mirrored |
| prefix | | M-7 | select-layout main-vertical-mirrored |
| prefix | | M-n | next-window -a |
| prefix | | M-o | rotate-window -D |
| prefix | | M-p | previous-window -a |
| prefix | | M-u | run-shell /home/mz/.tmux/plugins/tpm/bindings/clean_plugins |
| prefix | Yes | M-Up | resize-pane -U 5 |
| prefix | Yes | M-Down | resize-pane -D 5 |
| prefix | Yes | M-Left | resize-pane -L 5 |
| prefix | Yes | M-Right | resize-pane -R 5 |
| prefix | | C-b | send-prefix |
| prefix | | C-o | rotate-window |
| prefix | | C-z | suspend-client |
| prefix | Yes | C-Up | resize-pane -U |
| prefix | Yes | C-Down | resize-pane -D |
| prefix | Yes | C-Left | resize-pane -L |
| prefix | Yes | C-Right | resize-pane -R |
| prefix | Yes | S-Up | refresh-client -U 10 |
| prefix | Yes | S-Down | refresh-client -D 10 |
| prefix | Yes | S-Left | refresh-client -L 10 |
| prefix | Yes | S-Right | refresh-client -R 10 |
| root | | MouseDown1Pane | select-pane -t = \; send-keys -M |
| root | | MouseDown1Status | select-window -t = |
| root | | MouseDown2Pane | select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { paste-buffer -p } |
| root | | MouseDown3Pane | if-shell -F -t = "#{||:#{mouse_any_flag},#{&&:#{pane_in_mode},#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}}}" { select-pane -t = ; send-keys -M } { display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } } |
| root | | MouseDown3Status | display-menu -T "#[align=centre]#{window_index}:#{window_name}" -t = -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window } |
| root | | MouseDown3StatusLeft | display-menu -T "#[align=centre]#{session_name}" -t = -x M -y W Next n { switch-client -n } Previous p { switch-client -p } '' Renumber N { move-window -r } Rename n { command-prompt -I "#S" { rename-session "%%" } } '' "New Session" s { new-session } "New Window" w { new-window } |
| root | | MouseDrag1Pane | if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -M } |
| root | | MouseDrag1Border | resize-pane -M |
| root | | WheelUpPane | if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -e } |
| root | | WheelUpStatus | previous-window |
| root | | WheelDownStatus | next-window |
| root | | DoubleClick1Pane | select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel } |
| root | | TripleClick1Pane | select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" { send-keys -M } { copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel } |
| root | | M-MouseDown3Pane | display-menu -T "#[align=centre]#{pane_index} (#{pane_id})" -t = -x M -y M "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Top,}" < { send-keys -X history-top } "#{?#{m/r:(copy|view)-mode,#{pane_mode}},Go To Bottom,}" > { send-keys -X history-bottom } '' "#{?mouse_word,Search For #[underscore]#{=/9/...:mouse_word},}" C-r { if-shell -F "#{?#{m/r:(copy|view)-mode,#{pane_mode}},0,1}" "copy-mode -t=" ; send-keys -X -t = search-backward "#{q:mouse_word}" } "#{?mouse_word,Type #[underscore]#{=/9/...:mouse_word},}" C-y { copy-mode -q ; send-keys -l "#{q:mouse_word}" } "#{?mouse_word,Copy #[underscore]#{=/9/...:mouse_word},}" c { copy-mode -q ; set-buffer "#{q:mouse_word}" } "#{?mouse_line,Copy Line,}" l { copy-mode -q ; set-buffer "#{q:mouse_line}" } '' "#{?mouse_hyperlink,Type #[underscore]#{=/9/...:mouse_hyperlink},}" C-h { copy-mode -q ; send-keys -l "#{q:mouse_hyperlink}" } "#{?mouse_hyperlink,Copy #[underscore]#{=/9/...:mouse_hyperlink},}" h { copy-mode -q ; set-buffer "#{q:mouse_hyperlink}" } '' "Horizontal Split" h { split-window -h } "Vertical Split" v { split-window -v } '' "#{?#{>:#{window_panes},1},,-}Swap Up" u { swap-pane -U } "#{?#{>:#{window_panes},1},,-}Swap Down" d { swap-pane -D } "#{?pane_marked_set,,-}Swap Marked" s { swap-pane } '' Kill X { kill-pane } Respawn R { respawn-pane -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } "#{?#{>:#{window_panes},1},,-}#{?window_zoomed_flag,Unzoom,Zoom}" z { resize-pane -Z } |
| root | | M-MouseDown3Status | display-menu -T "#[align=centre]#{window_index}:#{window_name}" -t = -x W -y W "#{?#{>:#{session_windows},1},,-}Swap Left" l { swap-window -t :-1 } "#{?#{>:#{session_windows},1},,-}Swap Right" r { swap-window -t :+1 } "#{?pane_marked_set,,-}Swap Marked" s { swap-window } '' Kill X { kill-window } Respawn R { respawn-window -k } "#{?pane_marked,Unmark,Mark}" m { select-pane -m } Rename n { command-prompt -F -I "#W" { rename-window -t "#{window_id}" "%%" } } '' "New After" w { new-window -a } "New At End" W { new-window } |
| root | | M-MouseDown3StatusLeft| display-menu -T "#[align=centre]#{session_name}" -t = -x M -y W Next n { switch-client -n } Previous p { switch-client -p } '' Renumber N { move-window -r } Rename n { command-prompt -I "#S" { rename-session "%%" } } '' "New Session" s { new-session } "New Window" w { new-window } |
