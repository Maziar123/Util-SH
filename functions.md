| # | Line | Group | Function | Test Name |
|---|------|-------|----------|----------|
| 1 | 59 | SCRIPT INFORMATION | get_script_dir | test_get_script_dir |
| 2 | 68 | SCRIPT INFORMATION | get_script_name | test_get_script_name |
| 3 | 77 | SCRIPT INFORMATION | get_script_path | test_get_script_path |
| 4 | 86 | SCRIPT INFORMATION | get_line_number | test_get_line_number |
| 5 | 101 | LOGGING INITIALIZATION | log_init | test_log_init |
| 6 | 141 | LOGGING INITIALIZATION | _log_to_file | test_log_to_file |
| 7 | 153 | LOGGING FUNCTIONS | log_info | test_log_info |
| 8 | 158 | LOGGING FUNCTIONS | log_warn | test_log_warn |
| 9 | 163 | LOGGING FUNCTIONS | log_error | test_log_error |
| 10 | 168 | LOGGING FUNCTIONS | log_debug | test_log_debug |
| 11 | 175 | LOGGING FUNCTIONS | log_success | test_log_success |
| 12 | 181 | LOGGING FUNCTIONS | log_with_timestamp | test_log_with_timestamp |
| 13 | 190 | STRING FUNCTIONS | str_contains | test_str_contains |
| 14 | 197 | STRING FUNCTIONS | str_starts_with | test_str_starts_with |
| 15 | 204 | STRING FUNCTIONS | str_ends_with | test_str_ends_with |
| 16 | 211 | STRING FUNCTIONS | str_trim | test_str_trim |
| 17 | 221 | STRING FUNCTIONS | str_to_upper | test_str_to_upper |
| 18 | 226 | STRING FUNCTIONS | str_to_lower | test_str_to_lower |
| 19 | 231 | STRING FUNCTIONS | str_length | test_str_length |
| 20 | 236 | STRING FUNCTIONS | str_replace | test_str_replace |
| 21 | 245 | ARRAY FUNCTIONS | array_contains | test_array_contains |
| 22 | 257 | ARRAY FUNCTIONS | array_join | test_array_join |
| 23 | 278 | ARRAY FUNCTIONS | array_length | test_array_length |
| 24 | 285 | FILE & DIRECTORY FUNCTIONS | command_exists | test_command_exists |
| 25 | 290 | FILE & DIRECTORY FUNCTIONS | safe_mkdir | test_safe_mkdir |
| 26 | 297 | FILE & DIRECTORY FUNCTIONS | file_exists | test_file_exists |
| 27 | 302 | FILE & DIRECTORY FUNCTIONS | dir_exists | test_dir_exists |
| 28 | 307 | FILE & DIRECTORY FUNCTIONS | file_size | test_file_size |
| 29 | 316 | FILE & DIRECTORY FUNCTIONS | safe_copy | test_safe_copy |
| 30 | 344 | FILE & DIRECTORY FUNCTIONS | create_temp_file | test_create_temp_file |
| 31 | 355 | FILE & DIRECTORY FUNCTIONS | create_temp_dir | test_create_temp_dir |
| 32 | 366 | FILE & DIRECTORY FUNCTIONS | cleanup_temp | test_cleanup_temp |
| 33 | 392 | FILE & DIRECTORY FUNCTIONS | wait_for_file | test_wait_for_file |
| 34 | 407 | FILE & DIRECTORY FUNCTIONS | get_file_extension | test_get_file_extension |
| 35 | 419 | FILE & DIRECTORY FUNCTIONS | get_file_basename | test_get_file_basename |
| 36 | 428 | USER INTERACTION FUNCTIONS | confirm | test_confirm |
| 37 | 449 | USER INTERACTION FUNCTIONS | prompt_input | test_prompt_input |
| 38 | 465 | USER INTERACTION FUNCTIONS | prompt_password | test_prompt_password |
| 39 | 476 | SYSTEM & ENVIRONMENT FUNCTIONS | env_or_default | test_env_or_default |
| 40 | 489 | SYSTEM & ENVIRONMENT FUNCTIONS | is_root | test_is_root |
| 41 | 494 | SYSTEM & ENVIRONMENT FUNCTIONS | require_root | test_require_root |
| 42 | 502 | SYSTEM & ENVIRONMENT FUNCTIONS | parse_flags | test_parse_flags |
| 43 | 531 | SYSTEM & ENVIRONMENT FUNCTIONS | get_current_user | test_get_current_user |
| 44 | 536 | SYSTEM & ENVIRONMENT FUNCTIONS | get_hostname | test_get_hostname |
| 45 | 542 | OS DETECTION | get_os | test_get_os |
| 46 | 553 | OS DETECTION | get_linux_distro | test_get_linux_distro |
| 47 | 565 | OS DETECTION | get_arch | test_get_arch |
| 48 | 580 | OS DETECTION | is_in_container | test_is_in_container |
| 49 | 590 | DATE & TIME FUNCTIONS | get_timestamp | test_get_timestamp |
| 50 | 595 | DATE & TIME FUNCTIONS | format_date | test_format_date |
| 51 | 603 | DATE & TIME FUNCTIONS | time_diff_human | test_time_diff_human |
| 52 | 626 | NETWORKING FUNCTIONS | is_url_reachable | test_is_url_reachable |
| 53 | 639 | NETWORKING FUNCTIONS | get_external_ip | test_get_external_ip |
| 54 | 651 | NETWORKING FUNCTIONS | is_port_open | test_is_port_open |
| 55 | 663 | SCRIPT LOCK FUNCTIONS | create_lock | test_create_lock |
| 56 | 686 | SCRIPT LOCK FUNCTIONS | release_lock | test_release_lock |
| 57 | 697 | ERROR HANDLING | print_stack_trace | test_print_stack_trace |
| 58 | 707 | ERROR HANDLING | error_handler | test_error_handler |
| 59 | 724 | TRAP HANDLERS | setup_traps | test_setup_traps |
| 60 | 734 | DEPENDENCY CHECKS | check_dependencies | test_check_dependencies |
| 61 | 753 | INITIALIZATION | sh-globals_init | test_sh_globals_init |
| 62 | 787 | NUMBER FORMATTING FUNCTIONS | format_si_number | test_format_si_number |
| 63 | 839 | NUMBER FORMATTING FUNCTIONS | format_bytes | test_format_bytes |
| 64 | 881 | MESSAGE FUNCTIONS | msg | test_msg |
| 65 | 886 | MESSAGE FUNCTIONS | msg_info | test_msg_info |
| 66 | 891 | MESSAGE FUNCTIONS | msg_success | test_msg_success |
| 67 | 896 | MESSAGE FUNCTIONS | msg_warning | test_msg_warning |
| 68 | 901 | MESSAGE FUNCTIONS | msg_error | test_msg_error |
| 69 | 906 | MESSAGE FUNCTIONS | msg_highlight | test_msg_highlight |
| 70 | 911 | MESSAGE FUNCTIONS | msg_header | test_msg_header |
| 71 | 916 | MESSAGE FUNCTIONS | msg_section | test_msg_section |
| 72 | 944 | MESSAGE FUNCTIONS | msg_subtle | test_msg_subtle |
| 73 | 949 | MESSAGE FUNCTIONS | msg_color | test_msg_color |
| 74 | 958 | MESSAGE FUNCTIONS | msg_step | test_msg_step |
| 75 | 966 | MESSAGE FUNCTIONS | msg_debug | test_msg_debug |
| 76 | 976 | GET VALUE FUNCTIONS | get_number | test_get_number |
| 77 | 1022 | GET VALUE FUNCTIONS | get_string | test_get_string |
| 78 | 1060 | GET VALUE FUNCTIONS | get_path | test_get_path |
| 79 | 1113 | GET VALUE FUNCTIONS | get_value | test_get_value |
| 80 | 1205 | PATH NAVIGATION FUNCTIONS | get_parent_dir | test_get_parent_dir |
| 81 | 1211 | PATH NAVIGATION FUNCTIONS | get_parent_dir_n | test_get_parent_dir_n |
| 82 | 1225 | PATH NAVIGATION FUNCTIONS | path_relative_to_script | test_path_relative_to_script |
| 83 | 1234 | PATH NAVIGATION FUNCTIONS | to_absolute_path | test_to_absolute_path |
| 84 | 1249 | PATH NAVIGATION FUNCTIONS | source_relative | test_source_relative |
| 85 | 1267 | PATH NAVIGATION FUNCTIONS | source_with_fallbacks | test_source_with_fallbacks |
| 86 | 1297 | PATH NAVIGATION FUNCTIONS | parent_path | test_parent_path | 