# AGENTS.md

# Project Context & Guidelines for AI Assistants

This document provides essential context and strict architectural rules for AI assistants
(Junie, Gemini, GitHub Copilot, ChatGPT, etc.) working on the `setmy-info-scripts` project.

## Current code status and requirements to be used and followed

* `setmy-info-scripts` is a modular development environment preparation and system configuration project.
* Prepare and configure development terminals
* Support Linux and Windows environments
* Provide structured Docker-based workflows
* Maintain strict modular architecture
* Use CMake where build logic is required
* Provide documentation via man pages where applicable
* Keep binaries, libraries, scripts, and documentation clearly separated
* This repository is NOT a single monolithic application. It is a structured tooling ecosystem. It is modulith.
* Each functional domain MUST be isolated, Have a clearly defined responsibility, avoid tight coupling, avoid circular
  dependencies, be independently maintainable, declare dependencies explicitly (CMake or script-level)
* AI assistants MUST NOT collapse modules into a monolithic structure, introduce hidden cross-module dependencies, mix
  OS-specific logic inside shared modules, bypass the defined structure
* main production code is in src/main directory
* test code is in src/test directory
* Code is separated by languages cl, cmd, groovy, python, sh. Located as src/main/cl, src/main/cmd, src/main/groovy,
  src/main/python, src/main/sh.
* Man root is in src/main/man
* CMake files are in src/main/resources/cmake and src/test/resources/cmake
* Modules per domain.
* Module contains bin, lib, etc, in, lib folders.
* Module have module related cmake files, per language and domain in form
  src/main/resources/cmake/<LANGUAGE>/<DOMAIN or MODULE>
* Not all modules are already modularized. Some still remain in the src/main/sh/bin,src/main/sh/lib, src/main/sh/in,
  src/main/sh/bin. Same with CMake files directly in in src/main/resources/cmake/sh/.
* Cmake files are splited into bin.cmake, lib.cmake, etc.cmake, man.cmake, var.cmake, variables.cmake, sources.cmake,
  targets.cmake, functions.cmake, dependencies.cmake, configuration.cmake.
* Linux shell scripts should pe POSIX compatible shell scripts. And ready to port to FreeBSD, OpenIndiana, Debian.
* Windows scripts should be in .cmd format, should not be PowerShell scripts.

## DRAFT

# AGENTS.md

# Project Context & Guidelines for AI Assistants

This document provides essential context and strict architectural rules for AI assistants
(Junie, Gemini, GitHub Copilot, ChatGPT, etc.) working on the `setmy-info-scripts` project.

## Current code status and requirements to be used and followed

* `setmy-info-scripts` is a modular development environment preparation and system configuration project.
* Prepare and configure development terminals.
* Support Linux and Windows environments.
* Provide structured Docker-based workflows.
* Maintain strict modular architecture.
* Use CMake where build logic is required.
* Provide documentation via man pages where applicable.
* Keep binaries, libraries, scripts, configuration and documentation clearly separated.
* This repository is NOT a single monolithic application.
* It is a structured tooling ecosystem.
* It is modulith.

* Each functional domain MUST be isolated.
* Each functional domain MUST have a clearly defined responsibility.
* Each functional domain MUST avoid tight coupling.
* Each functional domain MUST avoid circular dependencies.
* Each functional domain MUST be independently maintainable.
* Each functional domain MUST declare dependencies explicitly (CMake or script-level).

* AI assistants MUST NOT collapse modules into a monolithic structure.
* AI assistants MUST NOT introduce hidden cross-module dependencies.
* AI assistants MUST NOT mix OS-specific logic inside shared modules.
* AI assistants MUST NOT bypass the defined structure.
* AI assistants MUST NOT reorganize directory layout unless explicitly instructed.
* AI assistants MUST NOT introduce architectural shortcuts.

* Main production code is located in `src/main`.
* Test code is located in `src/test`.

* Production code is separated by language:
  * `src/main/cl`
  * `src/main/cmd`
  * `src/main/groovy`
  * `src/main/python`
  * `src/main/sh`

* Test code follows equivalent language-based separation under `src/test`.

* Man root directory is located in `src/main/man`.
* Man pages are part of the public interface.
* Man pages MUST reflect actual CLI behavior.
* Man pages MUST be updated when CLI changes.
* Undocumented CLI flags are forbidden.
* Documentation drift is forbidden.

* CMake production files are located in `src/main/resources/cmake`.
* CMake test files are located in `src/test/resources/cmake`.

* CMake configuration is organized per language and per domain/module:
  * `src/main/resources/cmake/<LANGUAGE>/<DOMAIN_OR_MODULE>`

* Some CMake logic still exists in legacy flat structure:
  * `src/main/resources/cmake/sh/`
* Legacy flat CMake layout MUST NOT be extended for new development.
* New development MUST follow per-language per-domain modular CMake structure.

* CMake logic is split into dedicated files:
  * `bin.cmake`
  * `lib.cmake`
  * `etc.cmake`
  * `man.cmake`
  * `var.cmake`
  * `variables.cmake`
  * `sources.cmake`
  * `targets.cmake`
  * `functions.cmake`
  * `dependencies.cmake`
  * `configuration.cmake`

* CMake targets MUST be explicit.
* CMake dependencies MUST be explicit.
* Circular CMake target dependencies are forbidden.
* Global include leakage is forbidden.
* Implicit dependency resolution is forbidden.
* Monolithic CMake files are forbidden.

* Modules are organized per domain.
* A module may contain internal directories:
  * `bin`
  * `lib`
  * `etc`
  * `in`
* Module boundaries MUST be preserved.
* No module may access another module’s private internals.
* Shared logic MUST reside in `lib`, not in `bin`.
* Executable entrypoints MUST reside in `bin`.

* Not all modules are fully modularized yet.
* Some legacy shell layout still exists in:
  * `src/main/sh/bin`
  * `src/main/sh/lib`
  * `src/main/sh/in`
  * `src/main/sh/etc`
* Legacy flat shell layout MUST NOT be expanded.
* New shell logic MUST follow modular domain structure.

* Shell scripts MUST be POSIX compatible.
* Shell scripts MUST be portable to FreeBSD.
* Shell scripts MUST be portable to OpenIndiana.
* Shell scripts MUST be portable to Debian.
* Bash-only features MUST be avoided unless strictly required.
* Scripts MUST be idempotent.
* Scripts MUST use proper exit codes.
* Hardcoded distribution-specific paths are forbidden.

* Windows scripts MUST use `.cmd`.
* Windows scripts MUST use CMD syntax.
* Windows scripts MUST NOT use PowerShell.
* Windows scripts MUST NOT use `.ps1`.
* Windows scripts MUST NOT mix CMD and PowerShell.
* AI assistants MUST NEVER generate PowerShell for this project.

* Docker configuration MUST support structured development workflows.
* Docker MUST NOT contain business logic.
* Docker MUST NOT override modular architecture.
* Docker builds MUST integrate with CMake structure.
* Docker configuration MUST avoid host-specific assumptions.

* Dependency direction MUST remain stable.
* Cross-language implicit coupling is forbidden.
* Cross-domain hidden linkage is forbidden.
* Architecture stability has higher priority than feature speed.
* Explicit structure is mandatory.
* Implicit coupling is forbidden.
