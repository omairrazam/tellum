ActiveAdmin.register User, as: 'Tellum Users' do
  index do                            
    column :email                     
    column :current_sign_in_at        
    column :last_sign_in_at           
    column :sign_in_count             
    default_actions                   
  end                                 

  #permit_params :email,:username, :password
  filter :email                       

  form do |f|   
    f.semantic_errors *f.object.errors.keys                      
    f.inputs "User Details" do
      f.input :email                  
      f.input :password               
      f.input :password_confirmation  
    end                               
    f.actions                         
  end                                 
end                                   
