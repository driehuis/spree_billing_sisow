Spree::Core::Engine.routes.draw do

  resources :orders do
    resource :checkout, :controller => 'checkout' do
      member do
        get :sisow_cancel
        get :sisow_return
      end
    end
  end
  
  match '/sisow' => 'sisow_status#update', :via => :post, :as => :sisow_status_update
end
