
class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table(:links) do |t|
      t.string :image_url
      t.string :thread_url
      t.string :title
      t.boolean :is_posted, :default => false
      t.datetime :created_at
    end
    add_index :links, :image_url, :unique => true
  end
  def self.down
    drop_table :links
  end
end

