class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :quiz, null: false, foreign_key: true
      t.string :code, null: false
      t.integer :status, null: false, default: 0
      t.references :current_question, foreign_key: { to_table: :questions }, null: true
      t.datetime :question_opened_at

      t.timestamps
    end

    add_index :games, :code, unique: true
  end
end
