
call %LOADER_CMD% mvn
call %LOADER_CMD% ant
call %LOADER_CMD% gradle
call %LOADER_CMD% node
call %LOADER_CMD% groovy
call %LOADER_CMD% mn
call %LOADER_CMD% grails
call %LOADER_CMD% jfx
call %LOADER_CMD% python
call %LOADER_CMD% smi
call %LOADER_CMD% leiningen
call %LOADER_CMD% clojurescript
call %LOADER_CMD% cmake
call %LOADER_CMD% 7zip
call %LOADER_CMD% julia
call %LOADER_CMD% go
call %LOADER_CMD% k8s
call %LOADER_CMD% mk8s
call %LOADER_CMD% bazel
call %LOADER_CMD% postgres
call %LOADER_CMD% argo
call %LOADER_CMD% selenium
call %LOADER_CMD% graphviz
call %LOADER_CMD% k8ssealed
call %LOADER_CMD% sapling

if exist %USERPROFILE%\.term\profiles\tools.cmd (call %USERPROFILE%\.term\profiles\tools.cmd)
