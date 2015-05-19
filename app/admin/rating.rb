ActiveAdmin.register Rating, as: "Drops" do
  index do
    column :id
    column :drop_name do |v|
      v.try(:rating)
    end
    column :created_by do |v|
      v.try(:user).try(:full_name)
    end
    column :sub_drop do |v|
      v.try(:sub_rating)
    end
    column :box do |v|
      v.try(:tag).try(:tag_line)
    end
    column :comment do |v|
      v.try(:comment)
    end
    column :is_anonymous_rating do |v|
      v.try(:is_anonymous_rating)
    end
    column :audio_file_url do |v|
      v.try(:audio_file_url)
    end
    column :is_post_to_wall do |v|
      v.try(:is_post_to_wall)
    end
    column :is_flagged do |v|
      if v.try(:flagged_drop).present?
        v.try(:flagged_drop).try(:is_flagged)
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
      row :id
      row :drop_name do |v|
        v.try(:rating)
      end
      row :created_by do |v|
        v.try(:user).try(:full_name)
      end
      row :sub_drop do |v|
        v.try(:sub_rating)
      end
      row :box do |v|
        v.try(:tag).try(:tag_line)
      end
      row :comment do |v|
        v.try(:comment)
      end
      row :is_anonymous_rating do |v|
        v.try(:is_anonymous_rating)
      end
      row :audio_file_url do |v|
        v.try(:audio_file_url)
      end
      row :is_post_to_wall do |v|
        v.try(:is_post_to_wall)
      end
      row :is_flagged do |v|
        if v.flagged_drop.present?
          v.try(:flagged_drop).try(:is_flagged)
        else
          v.try(:is_flagged)
        end
      end
      row :created_at do |v|
        v.try(:created_at).in_time_zone('Eastern Time (US & Canada)')
      end
    end
  end
  form do |f|
    f.inputs do
      f.input :rating, label: "Drop Name"
      f.input :user
      f.input  :sub_rating, label: "Sub Drop"
      f.input  :comment
      f.input  :is_anonymous_rating
      f.input  :is_post_to_wall
      f.input  :audio_file_url
      f.input  :is_flagged
    end
    f.actions
  end
end
