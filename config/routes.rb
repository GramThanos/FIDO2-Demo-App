Rails.application.routes.draw do
	root 'app#index'
	match ':controller(/:action)', :via => :get
	match ':controller(/:action)', :via => :post
	#get 'app/index'
	#get 'app/login'
	#get 'app/register'
	#get 'app/dashboard'
	# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
