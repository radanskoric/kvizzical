class AddSecretPreviewTokenToQuizzes < ActiveRecord::Migration[8.1]
  def up
    add_column :quizzes, :secret_preview_token, :string
    add_index :quizzes, :secret_preview_token, unique: true

    Quiz.reset_column_information

    Quiz.find_each do |quiz|
      quiz.update_columns(secret_preview_token: generate_unique_token)
    end

    change_column_null :quizzes, :secret_preview_token, false
  end

  def down
    remove_index :quizzes, :secret_preview_token
    remove_column :quizzes, :secret_preview_token
  end

  private

  def generate_unique_token
    loop do
      token = SecureRandom.urlsafe_base64(18)
      break token unless Quiz.exists?(secret_preview_token: token)
    end
  end
end
