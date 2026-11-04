#!/usr/bin/env bash
# Runs every check. Needs: python3 -m pip install lupa
set -euo pipefail
cd "$(dirname "$0")"
R=../../original
python3 -I patch_check.py $R/legacy2017_chat/Chat_2015.lua $R/legacy2017_chat/Chat_2016.lua $R/legacy2017_chat/Chat_2017.lua $R/2017_chat_box.lua
python3 -I layout_sim.py
python3 -I runtime_sim.py | tail -1
python3 ../build.py >/dev/null
python3 -I gui_compile.py
