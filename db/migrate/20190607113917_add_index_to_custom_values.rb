class AddIndexToCustomValues < ActiveRecord::Migration
  def change
    add_index :custom_values, :customized_id
    add_index :custom_values, :value, length: { value: 2 }
  end
end
