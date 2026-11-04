#!/usr/bin/env python3
"""Builds fixed/<gui>.lua from original/<gui>.lua by adding the shared chat fix
(chatfix/ChatFix.lua) at one exact spot in each GUI. Fails if a spot isn't found
exactly once, so a changed original can't be patched wrongly by accident."""
import os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOCK = open(os.path.join(ROOT, "chatfix", "ChatFix.lua"), encoding="utf8").read().rstrip("\n") + "\n"


def once(src, old, new, what):
    n = src.count(old)
    if n != 1:
        sys.exit(f"{what}: expected 1 match, found {n}")
    return src.replace(old, new, 1)


def fix_2017(src):
    # The chat module lives in the Legacy model; patch its source before :Start() loads it.
    old = "\treturn Suite.launch(\n\t\tPath,\n\t\t{\n\t\t\trunscripts = true,\n\t\t\tdebug = true,\n\t\t\tverbose = true\n\t\t}\n\t)\n\nend)()"
    new = (
        BLOCK.replace("\n", "\n\t")
        + "\n\tlocal Model = Suite.launch(\n\t\tPath,\n\t\t{\n\t\t\trunscripts = true,\n\t\t\tdebug = true,\n\t\t\tverbose = true\n\t\t}\n\t)\n\n"
        + "\t-- Chat fix: scroll / vanishing bug and colours (see ChatFix block above)\n"
        + "\tpcall(function()\n"
        + "\t\tlocal Chat = Model.Core:FindFirstChild(tostring(Settings.Year)).NewRobloxGui.Modules.Chat\n"
        + "\t\tChat.Source = ChatFix.Patch(Chat.Source, \"2017 chat\")\n"
        + "\tend)\n\n\treturn Model\n\nend)()"
    )
    return once(src, old, new, "2017 Suite.launch")


def fix_2019(src):
    # The 2017 chat module is taken from Legacy2017.rbxm; patch it where it's prepared.
    src = once(
        src,
        "local Chat2017 = (function()\n",
        "local Chat2017 = (function()\n\n" + BLOCK + "\n",
        "2019 Chat2017 start",
    )
    return once(
        src,
        "\t\tlocal Compiled, CompileError = loadstring(Chat.Source)\n",
        "\t\t-- Chat fix: scroll / vanishing bug and colours\n"
        "\t\tChat.Source = ChatFix.Patch(Chat.Source, \"2019 chat\")\n\n"
        "\t\tlocal Compiled, CompileError = loadstring(Chat.Source)\n",
        "2019 compile",
    )


def fix_chatbox_loader(src, name):
    # 2021 and 2023 old download 2017_chat_box.lua; patch it before it runs.
    src = once(
        src,
        "    local CHAT_BOX_URL =",
        BLOCK.replace("\n", "\n    ") + "\n    local CHAT_BOX_URL =",
        name + " block",
    )
    return once(
        src,
        "        if chatSource then\n            local chunk, compileError = loadstring(chatSource)\n",
        "        if chatSource then\n"
        "            -- Chat fix: scroll / vanishing bug and colours\n"
        "            chatSource = ChatFix.Patch(chatSource, \"chat box\")\n"
        "            local chunk, compileError = loadstring(chatSource)\n",
        name + " loadstring",
    )


JOBS = {
    "2017_gui.lua": fix_2017,
    "2019_gui.lua": fix_2019,
    "2021_gui.lua": lambda s: fix_chatbox_loader(s, "2021"),
    "2023_old_gui.lua": lambda s: fix_chatbox_loader(s, "2023 old"),
}

if __name__ == "__main__":
    os.makedirs(os.path.join(ROOT, "fixed"), exist_ok=True)
    for name, fn in JOBS.items():
        src = open(os.path.join(ROOT, "original", name), encoding="utf8").read()
        out = fn(src)
        open(os.path.join(ROOT, "fixed", name), "w", encoding="utf8").write(out)
        print(f"fixed/{name}: {len(src)} -> {len(out)} bytes")
