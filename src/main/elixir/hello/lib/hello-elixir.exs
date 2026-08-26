exit_code =
  case System.argv() do
    [] -> 0
    [code | _] -> String.to_integer(code)
  end

IO.puts("Hello, world from #{File.cwd!()}!")

if exit_code != 0 do
  IO.puts("Exiting with code #{exit_code}.")
end

System.halt(exit_code)
