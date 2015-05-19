ActiveAdmin.register FlaggedDrop do
  controller do
    def scoped_collection
      FlaggedDrop.group(:rating_id)
    end
  end
  index do
    # selectable_column
    column :box_name do |v|
      v.try(:rating).try(:tag).try(:tag_line)
    end
    column :created_by do |v|
      v.try(:rating).try(:user).try(:full_name)
    end
    column :flagged_by do |v|
      v.try(:user).try(:full_name)
    end
    column :total_flagged_drop_count do |v|
      FlaggedDrop.where(rating_id: v.rating_id).count
    end
    column :drop_comment do |v|
      v.try(:rating).try(:comment)
    end
    column :audio_url do |v|
      v.try(:rating).try(:audio_file_url)
    end
    column :created_at do |v|
      v.try(:created_at).in_time_zone('Eastern Time (US & Canada)')
    end
    default_actions

  end
  show do |v|
    attributes_table do
      row :is_flagged
      row :box_name do |v|
        v.try(:rating).try(:tag).try(:tag_line)
      end
      row :created_by do |v|
        v.try(:rating).try(:user).try(:full_name)
      end
      row :flagged_by do |v|
        v.try(:user).try(:full_name)
      end
      row :total_flagged_drop_count do |v|
        FlaggedDrop.where(rating_id: v.rating_id).count
      end
      row :drop_comment do |v|
        v.try(:rating).try(:comment)
      end
      row :audio_url do |v|
        v.try(:rating).try(:audio_file_url)
      end
      row :created_at do |v|
        v.try(:created_at).in_time_zone('Eastern Time (US & Canada)')
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :is_flagged
      f.input :user_id
      f.input  :rating_id, label: "Drop"
    end
    f.actions
  end
end
