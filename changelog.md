## 2025-04-22
* Reorganized tmux utilities for better modularity and maintainability:
  * Created tmux_base_utils.sh for core low-level functions
  * Created tmux_script_generator.sh for script generation and boilerplate
  * Updated tmux_utils1.sh to use these new modular components
* Added new tmx_ prefix to all tmux functions for better namespace management
* Added new confirm_enter_esc function to sh-globals.sh for simpler user confirmations
* Updated documentation to reflect all changes
* Improved error handling and debugging in tmux utilities
* Enhanced script generation with more robust boilerplate

## 2025-04-21
* 77549a1 - Update files with today's changes (mz)
* b7899da - fix require start (mz)

## 2025-04-20
* 234480c - deepseek r1 (mz)
* 5c8d5ab - reeng  point1 (mz)
* 9e4fa52 - Add .gitignore to exclude archive and documentation folders, along with common file types (mz)
* a438597 - order bug (mz)
* b57e71d - Enhance parameter handling by initializing tracking arrays and resetting counters in parse_args function. Add comprehensive tests for single, two, and multiple parameters in usage examples. (mz)
* bb2d1c9 - Remove deprecated files and update .cursorignore to exclude new directories. The following files were deleted: functions.md, my_script.sh, README_PARAMS.md, sh-globals.md, Doc/README1.md, and several files in the getoptions-repo including examples, specs, and libraries. (mz)
* e503592 - Refactor parameter handling to use ordered arrays and simplify usage examples. Removed deprecated compatibility script and updated sample scripts to reflect new parameter format. (mz)

## 2025-04-17
* 5dbbacc - before alt (mz)

## 2025-04-16
* 565c93c - 2 (mz)
* c912af0 - Ut-Shell With tests (mz)
