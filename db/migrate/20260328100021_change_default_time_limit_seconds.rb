class ChangeDefaultTimeLimitSeconds < ActiveRecord::Migration[8.1]
  def up
    change_column_default :questions, :time_limit_seconds, from: 30, to: 15
    execute "UPDATE questions SET time_limit_seconds = 15"
  end

  def down
    change_column_default :questions, :time_limit_seconds, from: 15, to: 30
  end
end
