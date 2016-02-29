class AddIsRevealedViewedToReveal < ActiveRecord::Migration
  def change
    add_column :reveals, :is_revealed_viewed, :boolean, default: false
  end
end
