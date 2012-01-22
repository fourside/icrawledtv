
class AddColumnImgHashLinks < ActiveRecord::Migration
	def self.up
		add_column :links, :img_hash, :string
	end
	def self.down
		remove_column :links, :img_hash
	end
end

