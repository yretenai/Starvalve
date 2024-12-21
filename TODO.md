<!--
SPDX-FileCopyrightText: 2024 Legiayayana <ada@chronovore.dev>
SPDX-License-Identifier: EUPL-1.2
-->

# TODO

- [x] text vdf
- [x] binary vdf
- [x] appconfig vdf
- [ ] `clean` command (remove leftover files and linux-specific cache files from game directories)
- [ ] `uninstall [appid/name...]` command (uninstall a game without running uninstall scripts)
- [ ] `args <appid/name> <args>` command (edit game launch arguments)
- [ ] `move <appid/name> <library/label>` command (move game from one library to another)
- [ ] `list` command (list installed games)
- [ ] `library list` command (list libraries)
- [ ] `library label <library/label> <label>` command (set library label)
- [ ] `library purge <library/label` command (delete an entire library)
- [ ] `staging list` command (list all games that have other libraries as staging directories)
- [ ] `staging set <appid/name> <library/label>` command (manage the staging library for a given game)
- [ ] write more tests (mock binary vdf files?)
- [ ] write better docs
- [ ] generate docc

note: https://apple.github.io/swift-argument-parser/documentation/argumentparser/optiongroup/ & https://apple.github.io/swift-argument-parser/documentation/argumentparser/commandsandsubcommands
