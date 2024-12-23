<!--
SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
SPDX-License-Identifier: EUPL-1.2
-->

# TODO

- [x] text vdf
- [x] binary vdf
- [x] appconfig vdf
- [ ] `clean` command (remove leftover files and linux-specific cache files from game directories)
- [ ] `uninstall [appid...]` command (uninstall a game without running uninstall scripts)
- [ ] `args <appid> <args>` command (edit game launch arguments)
- [ ] `move <appid> <library>` command (move game from one library to another)
- [ ] `skip <appid>` command (cancel steam update)
- [x] `list <appid...>` command (list installed games)
- [x] `library list` command (list libraries)
- [x] `library label <library> <label>` command (set library label)
- [x] `library purge <library>` command (delete an entire library)
- [x] `staging list` command (list all games that have other libraries as staging directories)
- [x] `staging set <appid> <library>` command (manage the staging library for a given game)
- [ ] `workshop list <appid>` command (list workship items)
- [ ] write more tests (mock binary vdf files?)
- [ ] write better docs
- [ ] generate docc

note: https://apple.github.io/swift-argument-parser/documentation/argumentparser/optiongroup/ & https://apple.github.io/swift-argument-parser/documentation/argumentparser/commandsandsubcommands
