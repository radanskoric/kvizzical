class AddCreatorToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_reference :quizzes, :creator, foreign_key: { to_table: :users, on_delete: :nullify }
  end
end
