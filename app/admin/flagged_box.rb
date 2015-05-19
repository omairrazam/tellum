ActiveAdmin.register FlaggedBox do
  controller do
    def scoped_collection
      FlaggedBox.group(:tag_id)
    end
  end
  index do
    column :box_name do |v|
      v.try(:tag).try(:tag_line)
    end
    column :created_by do |v|
      v.try(:tag).try(:user).try(:full_name)
    end
    column :flagged_by do |v|
      v.try(:user).try(:full_name)
    end
    column :total_flagged_count do |v|
      FlaggedBox.where(tag_id: v.try(:tag_id)).try(:count)
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
        v.try(:tag).try(:tag_line)
      end
      row :created_by do |v|
        v.try(:tag).try(:user).try(:full_name)
      end
      row :flagged_by do |v|
        v.try(:user).try(:full_name)
      end
      row :total_flagged_box_count do |v|
        FlaggedBox.where(tag_id: v.try(:tag_id)).try(:count)
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
      f.input  :tag_id, label: "Box"
    end
    f.actions
  end
end
