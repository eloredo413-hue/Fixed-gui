# Fixed-gui: 2017-style chat fix

The 2017, 2019, 2021 and 2023 old GUIs all use the same 2017 chat window. It had two bugs:

1. **Scroll / vanishing chat.** After 50 messages the window drops the oldest one but never moves the
   rest up, so every new message is drawn further below the scroll area. You get a blank box that
   won't scroll.
2. **Colours.** Messages were plain text, so colour tags never showed. Messages from the game itself
   (red server messages) were ignored or stripped, and text colours set by chat-colour commands
   (`TextChatService.OnIncomingMessage`) never reached the window.

`chatfix/ChatFix.lua` fixes both by patching the chat module's source as it is loaded.

| File in `fixed/` | Chat it patches |
|---|---|
| `2017_gui.lua` | Chat module inside `Legacy2017.rbxm` |
| `2019_gui.lua` | same module, taken from `Legacy2017.rbxm` |
| `2021_gui.lua` | downloaded `2017_chat_box.lua` |
| `2023_old_gui.lua` | downloaded `2017_chat_box.lua` |

2023 new and 2024 use Roblox's own chat and are not affected.

Each fixed file is the original (`original/`) plus the ChatFix block at one spot. Rebuild with
`python3 chatfix/build.py`. Run the checks with `chatfix/tests/run_all.sh` (needs `pip install lupa`).

Not covered: colours from a chat-colour command need `getcallbackvalue` in the executor. Without it,
the scroll fix and rich text still work, but the command's colours can't be read.
