ActiveAdmin.register Tag, as: "Boxes" do
  index do
    column :id
    column :box_name do |v|
      v.try(:tag_line)
    end
    column :created_by do |v|
      v.try(:user).try(:full_name)
    end
    column :box_description do |v|
      v.try(:tag_description)
    end
    column :box_title do |v|
      v.try(:tag_title)
    end
    column :open_date do |v|
      v.try(:open_date)
    end
    column :close_date do |v|
      v.try(:close_date)
    end
    column :is_private do |v|
      v.try(:is_private)
    end
    column :is_allow_anonymous do |v|
      v.try(:is_allow_anonymous)
    end
    column :is_post_to_wall do |v|
      v.try(:is_post_to_wall)
    end
    # column :is_locked do |v|
    #   v.try(:is_locked)
    # end
    column :is_flagged do |v|
      if v.try(:flagged_box).present?
        v.try(:flagged_box).try(:is_flagged)
      else
        v.try(:is_flagged)
      end
    end
    column :created_at do |v|
      v.try(:created_at).in_time_zone('Eastern Time (US & Canada)')
    end
    default_actions
  end
  show do |v|
    attributes_table do
      row :box_name do |v|
        v.try(:tag_line)
      end
      row :created_by do |v|
        v.try(:user).try(:full_name)
      end
      row :box_description do |v|
        v.try(:tag_description)
      end
      row :box_title do |v|
        v.try(:tag_title)
      end
      row :open_date do |v|
        v.try(:open_date)
      end
      row :close_date do |v|
        v.try(:close_date)
      end
      row :is_private do |v|
        v.try(:is_private)
      end
      row :is_allow_anonymous do |v|
        v.try(:is_allow_anonymous)
      end
      row :is_post_to_wall do |v|
        v.try(:is_post_to_wall)
      end
      # row :is_locked do |v|
      #   v.try(:is_locked)
      # end
      row :is_flagged do |v|
        if v.try(:flagged_box).present?
          v.try(:flagged_box).try(:is_flagged)
        else
          v.try(:is_flagged)
        end
      end
      row :drops do |v|
        v.try(:ratings)
      end
      row :created_at do |v|
        v.try(:created_at).in_time_zone('Eastern Time (US & Canada)')
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :tag_line, label: "Box Name"
      f.input :user
      f.input  :tag_description, label: "Box Description"
      f.input  :tag_title, label: "Box Title"
      f.input  :open_date
      f.input  :close_date
      f.input  :is_private
      f.input  :is_allow_anonymous
      f.input  :is_post_to_wall
      f.input  :is_locked
      f.input  :is_flagged
    end
    f.actions
  end
end
