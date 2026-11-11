# Set in the environment, a value wins over the default here.
SMI_ELIXIR_LIB_DIR="${SMI_ELIXIR_LIB_DIR:-$(smi-lib-location)/elixir}"
# Compiled Elixir and Erlang applications, one directory each: modules/<app>/ebin and
# modules/<app>/priv. A script puts them on the code path with ERL_LIBS="${SMI_ELIXIR_MODULES_DIR}".
SMI_ELIXIR_MODULES_DIR="${SMI_ELIXIR_MODULES_DIR:-${SMI_ELIXIR_LIB_DIR}/modules}"
