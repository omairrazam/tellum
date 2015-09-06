Tellum::Application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users, controllers: {sessions: "sessions", passwords: "api/passwords", confirmations: "api/confirmations"}
  ActiveAdmin.routes(self)
  get '/terms-of-service', to: 'welcome#termsofservice'
  get '/privacy-policy', to: 'welcome#privacypolicy'
  get '/contactus', to: 'welcome#contactus'
  namespace :api do
    resources :users do
      collection do
        get :search_user
        put :update
        post :facebook_login
        post :twitter_login
        post :profile_completion
        post :facebook_profile_completion
        get :user_detail
        get :my_profile
        get :update_badge_count
        put :edit_profile
        post :send_confirmation_email_again
        post :check_user_followings
      end
    end
    post '/users/login', :to => 'sessions#create'
    delete '/sessions/sign_out', :to => 'sessions#destroy'
    resource :tags do
      member do
        get :tag_detail
        get :get_box_description
        get :get_total_drops
        get :box_time_line
        get :check_tag_expiry
        post :lock_tag
        post :check_flag
        get :tag_line_including_locked
        get :search_tagline_title_contains
        get :search_tagline_exectmatch
        get :search_tagline_any_where
        put :update_tag_info
        get :taglines_and_ratings_by_followings
        get :taglines_and_ratings_by_followings_PTR
        get :tagslines_by_followings
        get :ratings_by_followings
        get :tagslines_most_popular
        get :ratings_most_popular
        get :taglines_and_ratings_most_popular
        get :tagslines_by_followings
        get :ratings_by_followings
        get :tagslines_most_popular
        get :ratings_most_popular
        get :taglines_and_ratings_most_popular
        get :tagslines_by_followings_PTR
        get :ratings_by_followings_PTR
        get :tagslines_most_popular_PTR
        get :ratings_most_popular_PTR
        get :taglines_and_ratings_most_popular_PTR
        get :tagslines_by_user
        get :ratings_by_user
        get :taglines_and_ratings_by_user
        get :tagslines_by_user
        get :ratings_by_user
        get :taglines_and_ratings_by_user
        get :tagslines_by_user_PTR
        get :ratings_by_user_PTR
        get :search_tagline_exectmatch_with_status
        get :taglines_and_ratings_by_user_PTR
        get :ratings_of_a_tag_ordered_by_most_popular
        get :taglines_and_ratings_by_followings_and_me
        get :taglines_and_ratings_by_followings_and_me_PTR
      end
    end
    resource :ratings do
      member do
        post :like_rating
        post :check_flag
        post :unlike_rating
        get :likes_list
        get :ratings_of_a_tag
        get :ratings_of_a_tag_PTR
      end
    end
    resource :comments do
      member do
        get :comments_rating
        get :comments_rating_PTR
      end
    end
    resource :user_follow do
      member do
        post :unfollow_user
        post :remove_follower_user
        post :remove_following_request
        post :send_follow_request
        post :accept_follow_request
        get :my_followers
        get :followers_of_user
        get :my_followings
        get :followings_of_user
        post :follow_users
      end
    end
    resource :messages do
      member do
        post :send_message
        get :messages_list
        get :messangers_list
      end
    end
    resource :reveals do
      member do
        post :reveal_yourself
        # get :all_notifications
        post :reveal_status
        get :revealed_user
      end
    end
    resource :notifications do
      member do
        get :all_notifications
        get :all_notifications_PTR
        get :all_notifications_count
      end
    end

  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #get 'test/:first_name' => 'test#index'
  #match '/404', to: "error_pages#handle_404"



  #get 'tests/:first_name', :action => 'index', :controller => "tests", :as => 'tests'
  #post 'tests/:first_name/:last_name', :action => 'create', :controller => "tests", :as => "tests"
  #resources :test

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end