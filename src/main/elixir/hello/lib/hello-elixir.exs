defmodule HelloElixir do
  @moduledoc """
  Example helpers showing how values can be piped from one function to the next.
  """

  # POSIX shells report the exit status of a command as a single byte.
  @min_exit_code 0
  @max_exit_code 255

  # Returned when the requested exit code is not a usable POSIX exit status.
  @invalid_exit_code 1

  @doc """
  Takes the command line arguments and returns the exit code to use.

  Returns 0 when no argument was given. Returns #{@invalid_exit_code} when the
  argument is not an integer, or falls outside the #{@min_exit_code}..#{@max_exit_code}
  range a POSIX shell can report.
  """
  def parse_exit_code([]), do: @min_exit_code

  def parse_exit_code([code | _]) do
    case Integer.parse(code) do
      {value, ""} when value >= @min_exit_code and value <= @max_exit_code -> value
      _ -> @invalid_exit_code
    end
  end

  @doc """
  Prints the exit code when it is non-zero and stays silent otherwise.
  Returns the code unchanged so it can be piped onwards.
  """
  def print_exit_code(exit_code) do
    if exit_code != @min_exit_code do
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
