class CreateAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :answers do |t|
      t.references :question, null: false, foreign_key: true
      t.string :body, null: false
      t.boolean :correct, null: false, default: false

      t.timestamps
    end

    add_index :answers, :question_id, unique: true, where: "correct = 1", name: "index_answers_one_correct_per_question"
  end
end
