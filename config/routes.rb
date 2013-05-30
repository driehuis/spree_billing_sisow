Spree::Core::Engine.routes.draw do

  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        get :sisow_cancel
        get :sisow_return
      end
    end
  end

  namespace :admin do
    resource :sisow, :only => [:edit, :update], :controller => "sisow"
  end
  
  match '/sisow/:order_id' => 'sisow_status#update', :via => :get, :as => :sisow_status_update
end
