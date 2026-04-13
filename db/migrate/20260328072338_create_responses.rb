class CreateResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :responses do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :answer, null: false, foreign_key: true
      t.datetime :responded_at, null: false
      t.integer :score, null: false, default: 0

      t.timestamps
    end

    add_index :responses, [ :participant_id, :question_id ], unique: true
  end
end
