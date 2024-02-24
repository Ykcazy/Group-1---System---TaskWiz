defmodule TaskManager.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string
      add :status, :string
      add :description, :string
      add :due_date, :string

      timestamps(type: :utc_datetime)
    end
  end
end
