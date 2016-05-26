defmodule Cog.Commands.Help do
  use Cog.Command.GenCommand.Base,
    bundle: Cog.embedded_bundle

  use Cog.Models
  alias Cog.Repository.Commands

  @moduledoc """
  Prints help documentation for all commands.

  USAGE
    help [FLAGS] <command>

  ARGS
    command  prints long form documentation

  FLAGS
    -d, --disabled  Lists all disabled commands

  EXAMPLES
    help
    > operable:alias
      operable:bundle
      operable:echo
      operable:filter
      operable:group
      operable:help
      operable:max
      operable:min
      operable:permissions
      operable:raw
      operable:relay
      operable:relay-group
      operable:role
      operable:rules
      operable:seed
      operable:sleep
      operable:sort
      operable:sum
      operable:table
      operable:unique
      operable:wc
      operable:which
  """

  rule "when command is #{Cog.embedded_bundle}:help allow"

  option "disabled", short: "d", type: "bool", required: false

  def handle_message(%{args: [], options: options} = req, state) do
    commands = options
    |> find_commands
    |> Enum.sort_by(&CommandVersion.full_name/1)

    {:reply, req.reply_to, "help", commands, state}
  end

  def handle_message(%{args: [command]} = req, state) do
    case find_command(command) do
      [%{documentation: documentation} = command] when is_binary(documentation) ->
        {:reply, req.reply_to, "help-command", [command], state}
      [%{documentation: nil} = command_version] ->
        name = CommandVersion.full_name(command_version.command)
        {:error, req.reply_to, "Command #{inspect name} does not have any documentation", state}
      [] ->
        {:error, req.reply_to, "Command #{inspect command} does not exist", state}
      commands when is_list(commands) ->
        names = commands
        |> Enum.map(&(&1.command))
        |> Enum.map_join("\n", &CommandVersion.full_name/1)

        message = """
        Multiple commands found for command #{inspect command}. Please choose one:

        #{names}
        """

        {:error, req.reply_to, message, state}
    end
  end

  def handle_message(req, state) do
    {:reply, req.reply_to, "usage", %{usage: @moduledoc}, state}
  end

  defp find_commands(%{"disabled" => true}),
    do: Commands.highest_disabled_versions
  defp find_commands(%{}),
    do: Commands.enabled

  defp find_command(command),
    do: Commands.enabled_by_any_name(command)
end
