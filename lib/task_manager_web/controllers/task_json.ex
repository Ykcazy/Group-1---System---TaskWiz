defmodule TaskManagerWeb.TaskJSON do
  alias TaskManager.Tasks.Task

  @doc """
  Renders a list of tasks.
  """
  def index(%{tasks: tasks}) do
    %{tasks: for(task <- tasks, do: data(task))}
  end

  @doc """
  Renders a single task.
  """
  def show(%{task: task}) do
    %{task: data(task)}
  end

  defp data(%Task{} = task) do
    %{
      id: task.id,
      title: task.title,
      status: task.status,
      description: task.description,
      due_date: task.due_date
    }
  end
end
