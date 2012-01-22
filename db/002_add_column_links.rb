
class AddColumnLinks < ActiveRecord::Migration
	def self.up
		add_column :links, :tv, :string
	end
	def self.down
		remove_column :links, :tv
	end
end

