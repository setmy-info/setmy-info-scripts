
- [] Task: Refactor ai profiles this way, that these files are threated as bourn shell scripts part, thous should be
  imported. Before import in current folder checks ai.sh existance and when present imports that first. The current
  folder is software projects folders. Imported ai.sh can contain variable values for the next step. The next step is
  to evaluate profile.md files; those can contain variables, which should be replaced. For example, java.md has Java
  versions; thes should be as variables ${JAVA} and ${JAVA_VERSION}. Values are defined in ai.sh - JAVA=25 and
  JAVA_VERSION=25.0.2 Example PoC, but still with a line feed problem to solve:

```shell
  [has@has repacer]$ cat ai.sh 
  #!/bin/sh

  # 1. That should be imported from project root folder that is working directory.
  SOME_VARIABLE="Some variable value!"

  # 2. File name is profile used to be shown out
  FILE_NAME=example.md
  CONTENT=$(cat ${FILE_NAME})
  eval "NEW_CONTENT=\"${CONTENT}\""

  # 3. Show out MD file with replaced values. NB! Problem, new lines are not escaped into \n or something all exists as sngle line
  echo ${NEW_CONTENT}

  exit 0

  [has@has repacer]$ cat example.md 
  # Example MD

  Should use vaiable: ${SOME_VARIABLE}
```
