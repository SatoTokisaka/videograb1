class AddFileUrlToVideos < ActiveRecord::Migration[8.0]
  def change
    add_column :videos, :file_url, :string
  end
end
