Rubyfiddle::Application.routes.draw do
  root to: "fiddles#index"
  resources :fiddles do
    member do
      put :fork
    end
  end
  resources :uploads


  post '' => 'fiddles#index'
  get 'fiddles/:code_type/:id' => 'fiddles#show', :as => :unversioned_fiddle, :constraints => {:code_type => /(dockerfile|compose)/}
  get 'fiddles/:code_type/:id/:version' => 'fiddles#show', :as => :versioned_fiddle, :constraints => {:code_type => /(dockerfile|compose)/, :version=> /\d*/}
  get 'fiddles/:id/:version' => 'fiddles#old_redirect', :as => :old_versioned_fiddle, :constraints => {:version=> /\d*/}

  get 'apphub' => 'fiddles#apphub'
  get 'faq' => 'static_pages#faq'
  get 'upload/list_files' => 'uploads#show_uploaded_files'
  #get 'signup' => 'users#new', as: :signup
  post 'upload/clear' => 'uploads#clear_files'
  post 'plays/run' => 'plays#run', as: :play
  post 'linter' => 'linter#lint', as: :linter
end
