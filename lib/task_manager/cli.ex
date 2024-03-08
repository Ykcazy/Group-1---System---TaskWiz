defmodule TaskManager.Cli do
  @moduledoc """
  Command Line Interface for Task Management System

  This module provides a command line interface (CLI) for interacting with
  a Task Management System. It allows users to view, add, edit, and delete tasks.

  ## Usage

  1. Start the CLI by calling `TaskManager.Cli.start`.
  2. The CLI will display a menu with options to view, add, edit, or delete tasks.
  3. Follow the prompts to perform the desired action.

  ## Example
  iex -S mix
  TaskManager.Cli.start
  """
  alias TaskManager.Tasks
  alias TableRex.Table

  @doc """
  Starts the Task Manager CLI.
  """
  def start() do
    loop()
  end

  @doc """
  Main loop for the Task Manager CLI.
  """
  def loop() do
    display_menu()
    handle_input()
    loop()
  end

  @doc """
  Displays a prompt to continue to the next step.
  """
  def continue() do
    IO.puts("\nPress Enter to continue...")
    IO.gets("")
  end

  @doc """
  Displays the main menu.
  """
  def display_menu() do
    IO.puts """


    =========== TaskWiz ============
    === A Task Management System ===

    1. View All Tasks
    2. Add a Task
    3. Edit a Task
    4. Delete a Task
    5. EXIT
    """
  end

  @doc """
  Handles user input.
  """
  def handle_input() do
    IO.puts "Enter your choice: "
    input = IO.gets("") |> String.trim()
    pick_task(input)
  end

  @doc """
  Picks a task based on user input.
  """
  def pick_task("1") do
    view_all_tasks()
    continue()
  end
  def pick_task("2"), do: add_task()
  def pick_task("3"), do: edit_task()
  def pick_task("4"), do: delete_task()
  def pick_task("5"), do: exit_program()
  def pick_task(_) do
    IO.puts("\nERROR! Wrong input. Please try again.")
    continue()
  end


  defp display_task(%TaskManager.Tasks.Task{id: id, title: title, status: status,
  description: description, due_date: due_date}) do
    [id, title, status, description, due_date]
  end

  @doc """
  Displays all tasks.
  """
def view_all_tasks() do
  tasks = Tasks.list_tasks()

  if Enum.empty?(tasks) do
    IO.puts("No tasks available.")
  else
    IO.puts("\n\n=== MY TASKS ===\n")

    header = ["Number", "ID", "Title", "Status", "Description", "Due Date"]
    rows = Enum.with_index(tasks)
           |> Enum.map(fn {task, idx} -> [idx + 1 | display_task(task)] end)

    Table.new(rows, header)
    |> Table.render!(horizontal_style: :all, top_frame_symbol: "+", header_separator_symbol: "=", horizontal_symbol: "-", vertical_symbol: "|")
    |> IO.puts

    {tasks}
  end
end


  @doc """
  Adds a new task.
  """
  def add_task() do
    IO.puts("\n\n===== ADD A TASK =====\n")
    task_params = get_task_params()
    case Tasks.create_task(task_params) do
      {:ok, _} -> IO.puts("\nTask added successfully.")
      {:error, changeset} -> IO.puts("\nFailed to add task: #{inspect(changeset.errors)}")
    end
    continue()
  end


  defp get_task_params() do

    title = get_task_title()

    description = get_task_description()

    due_date = get_due_date()

    %{title: title, status: "Not Started", description: description, due_date: due_date}
  end


  defp get_task_title() do
    IO.puts "\nEnter Title: "
    title = IO.gets("") |> String.trim()

    if String.length(title) > 0 do
      title
    else
      IO.puts ("\nTitle cannot be empty. Please enter a title.")
      continue()
      get_task_title()
    end
  end

  defp get_task_description() do
    IO.puts ("\nEnter Description: ")
    description = IO.gets("") |> String.trim()

    if String.length(description) > 0 do
      description
    else
      IO.puts ("\nDescription cannot be empty. Please enter a description.")
      continue()
      get_task_description()
    end
  end

  defp get_due_date() do
    IO.puts "\nEnter Due Date (YYYY-MM-DD): "
    today = Date.utc_today()
    due_date = IO.gets("") |> String.trim()

    case Date.from_iso8601(due_date) do
      {:ok, entered_date} ->
        if Date.compare(entered_date, today) >= 0 do
          due_date
        else
          IO.puts ("\nDue date must be today or in the future.")
          continue()
          get_due_date()  # Recursively call the function again
        end

      _ ->
        IO.puts ("\nInvalid date format. Please enter the date in the format YYYY-MM-DD.")
        continue()
        get_due_date()  # Recursively call the function again
    end
  end

  @doc """
  Edits an existing task.
  """
  def edit_task() do
    IO.puts("""

    ====== EDIT A TASK =======
    Which do you want to edit?

    1. Edit a Title
    2. Edit a Status
    3. Edit a Description
    4. Edit a Due Date
    5. Back to main menu
    """)

    IO.puts "Enter your choice: "
    input = IO.gets("") |> String.trim()

    pick_edit(input)
  end

  @doc """
  Picks the field to edit for a task.
  """
  def pick_edit("1"), do: edit_task_field(:title)
  def pick_edit("2"), do: edit_task_field(:status)
  def pick_edit("3"), do: edit_task_field(:description)
  def pick_edit("4"), do: edit_task_field(:due_date)
  def pick_edit("5"), do: loop()
  def pick_edit(_) do
    IO.puts("\nERROR! Wrong input. Please try again.")
    continue()
    edit_task()
  end

  @doc """
  Edits a specific field of a task.
  """
def edit_task_field(field) do
  {tasks} = view_all_tasks()

  IO.puts("\nEnter number of task to edit: ")
  input = IO.gets("") |> String.trim()

  case Integer.parse(input) do
    {:error, _} ->
      IO.puts("\nInvalid input. Please enter a number.")
      continue()
      edit_task_field(field)
    {number, _} when number > 0 ->
      case number <= length(tasks) do
        true ->
          task = Enum.at(tasks, number - 1)
          new_value = get_new_value(field)
          attrs = Map.put(%{}, field, new_value)

          case Tasks.update_task(task, attrs) do
            {:ok, _} ->
              IO.puts("\n#{String.capitalize(to_string(field))} updated successfully.")
              continue()
            {:error, changeset} ->
              IO.puts("\nFailed to update task: #{inspect(changeset.errors)}")
              continue()
          end
        false ->
          IO.puts("\nInvalid task number.")
          continue()
          edit_task_field(field)
      end
    _ ->
      IO.puts("\nInvalid input. Please enter a valid number.")
      continue()
      edit_task_field(field)
  end
end


  defp get_new_value(:title) do
    input = get_input("\nEnter NEW title: ")
    case String.trim(input) do
      "" ->
        IO.puts("\nTitle cannot be empty. Please enter a title.")
        continue()
        get_new_value(:title)
      title ->
        title
    end
  end

  defp get_new_value(:description) do
    input = get_input("\nEnter NEW description: ")
    case String.trim(input) do
      "" ->
        IO.puts("\nDescription cannot be empty. Please enter a description.")
        continue()
        get_new_value(:description)
      description ->
        description
    end
  end


  defp get_new_value(:due_date) do
    get_due_date()
  end


  defp get_new_value(:status) do
    IO.puts("""

    Select a NEW status:

    0 - "Not Started"
    1 - "In Progress"
    2 - "Done"

    """)
    get_input("Enter NEW status: ")
    |> status()

  end


  defp status("0"), do: "Not Started"
  defp status("1"), do: "In Progress"
  defp status("2"), do: "Done"
  defp status(_) do
    IO.puts("\nERROR! Wrong input. Please try again.")
    continue()
    get_new_value(:status)
  end


  defp get_input(prompt) do
    IO.puts(prompt)
    input = IO.gets("") |> String.trim()
    input
  end

  @doc """
  Deletes an existing task.
  """
def delete_task() do
  {tasks} = view_all_tasks()

  IO.puts("\n\n===== DELETE A TASK =====\n")
  IO.puts("\nEnter number of task to delete: ")
  input = IO.gets("") |> String.trim()

  case Integer.parse(input) do
    {:error, _} ->
      IO.puts("\nInvalid input. Please enter a number.")
      continue()
      delete_task()

    {number, _} when number > 0 ->
      if number <= length(tasks) do
        task = Enum.at(tasks, number - 1)
        case Tasks.delete_task(task) do
          {:ok, _} ->
            IO.puts("\nTask deleted successfully.")
          {:error, changeset} ->
            IO.puts("\nFailed to delete task: #{inspect(changeset.errors)}")
        end
      else
        IO.puts("\nInvalid task number.")
        continue()
        delete_task()
      end

    _ ->
      IO.puts("\nInvalid input. Please enter a valid number.")
      continue()
      delete_task()
  end

  continue()
end


  @doc """
  Exits the CLI.
  """
  def exit_program() do
    IO.puts "\nExiting..."
    System.halt(0)
  end


end
