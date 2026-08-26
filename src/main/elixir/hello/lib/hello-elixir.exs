defmodule HelloElixir do
  @moduledoc """
  Example helpers showing how values can be piped from one function to the next.
  """

  @doc """
  Takes the command line arguments and returns the exit code to use.
  Defaults to 0 when no argument was given.
  """
  def parse_exit_code([]), do: 0
  def parse_exit_code([code | _rest]), do: String.to_integer(code)

  @doc """
  Prints the exit code when it is non-zero and stays silent otherwise.
  Returns the code unchanged so it can be piped onwards.
  """
  def print_exit_code(exit_code) do
    if exit_code != 0 do
      IO.puts("Exiting with code #{exit_code}.")
    end

    exit_code
  end
end

IO.puts("Hello, world from #{File.cwd!()}!")

System.argv()
|> HelloElixir.parse_exit_code()
|> HelloElixir.print_exit_code()
|> System.halt()
