class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :tag_line
      t.string :tag_title
      t.string :tag_description
      t.datetime :open_date
      t.datetime :close_date
      t.boolean :is_private
      t.boolean :is_allow_anonymous
      t.boolean :is_post_to_wall
      t.timestamps
    end

  end
end
