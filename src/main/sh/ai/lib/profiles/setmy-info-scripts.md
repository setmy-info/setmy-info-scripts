- `setmy-info-scripts` is a modular development environment preparation and system configuration project.
- `setmy-info-scripts` cloned code resides usually at C:\sources\setmy.info\submodules\setmy-info-scripts for Windows
  machines and in   ~/sources/components/setmy.info/submodules/setmy-info-scripts folder for Unixes. Investigate what is
  there and use as supposed in new scripts in any other projects. Expecting, that OS have that software installed.
- Prepare and configure development terminals
- Support Linux and Windows environments
- Provide structured Docker-based workflows
- Maintain strict modular architecture
- Use CMake where build logic is required
- Keep binaries, libraries, scripts, and documentation clearly separated
- This repository is NOT a single monolithic application. It is a structured tooling ecosystem. It is modulith.
- Each functional domain MUST be isolated, Have a clearly defined responsibility, avoid tight coupling, avoid circular
  dependencies, be independently maintainable, declare dependencies explicitly (CMake or script-level)
- AI assistants MUST NOT collapse modules into a monolithic structure, introduce hidden cross-module dependencies, mix
  OS-specific logic inside shared modules, bypass the defined structure
- the main production code is in the src / main directory
- test code is in the src / test directory
- Code is separated by languages cl, cmd, groovy, python, sh. Located as src/main/cl, src/main/cmd, src/main/groovy,
  src/main/python, src/main/sh.
- Man root is in src/main/man
- CMake files are in src/main/resources/cmake and src/test/resources/cmake
- Modules per domain.
- Module contains bin, lib, etc, in, lib folders.
- Module have module related cmake files, per language and domain in form
  src/main/resources/cmake/<LANGUAGE>/<DOMAIN or MODULE>
- Not all modules are already modularized. Some still remain in the src/main/sh/bin,src/main/sh/lib, src/main/sh/in,
  src/main/sh/bin. Same with CMake files directly in src/main/resources/cmake/sh/.
- Cmake files are splited into bin.cmake, lib.cmake, etc.cmake, man.cmake, var.cmake, variables.cmake, sources.cmake,
  targets.cmake, functions.cmake, dependencies.cmake, configuration.cmake.
- Linux shell scripts should pe POSIX compatible shell scripts. And ready to port to FreeBSD, OpenIndiana, Debian.
- Windows scripts should be in .cmd or PowerShell (.ps1) format. Previously PowerShell was restricted, but it is now
  allowed. However, PowerShell is NOT allowed for *.profile and *.package files. PowerShell should be executed from CMD.
- shell scripts are not always in specific form like "smi-*" or "*.sh"
- Man pages follow the same folder structure like they are modularized.
- Windows additional software place is in C:\pub
- `setmy-info-scripts` Windows related scripts and exes are in C:\pub\setmy.info\bin and importable scripts and
  libraries in "C:\pub\setmy.info\lib"
- `setmy-info-scripts` Unixes related scripts and exes are in /opt/setmy.info/bin and importable scripts and libraries
  in "C:\pub\setmy.info\lib".
- Adding a new script for Unixes, then a man page should be created also
- Newly added scripts should have in for # Copyright (C) YYYY Imre Tabur <imre.tabur@mail.ee>
- Users config files are located in a folder named .setmy.info in the user home directory.
- New scripts should be added into cmake scripts
- Update the changelog file about changes in very detailed form, so it can be tracked in the future for testing changes
  for testings.
- FHS <PARTNAME> is setmy.info. bin  and lib directories should be under /opt related directories.
