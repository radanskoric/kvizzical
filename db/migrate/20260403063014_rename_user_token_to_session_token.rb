class RenameUserTokenToSessionToken < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :token, :session_token
    rename_index :users, :index_users_on_token, :index_users_on_session_token
  end
end
