class AppController < ApplicationController
	def index
		# If user is logged in
		if session[:is_logged_in] && session[:is_logged_in] == true
			# goto Dashboard
			redirect_to(:action => 'dashboard') and return
		# If not
		else
			# goto login
			redirect_to(:action => 'login') and return
		end
	end

	def login
		# If user is logged in
		if session[:is_logged_in] && session[:is_logged_in] == true
			# goto Dashboard
			redirect_to(:action => 'dashboard') and return
		end

		# If this was a post
		if request.post?
			# Try to find the user and authenticate him
			user = nil
			if params["username-or-email"].include?('@')
				user = User.find_by(email: params["username-or-email"])
			else
				user = User.find_by(name: params["username-or-email"])
			end
			# If user was found and authentication was successful
			if user
				# Session info
				session[:user_id] = user.id
				session[:user_email] = user.email
				session[:user_name] = user.name
				session[:is_logged_in] = true
				# Go to dashboard
				redirect_to(:action => 'dashboard') and return

			# User was not found or Authentication failed
			else
				# Show error message
				@message_error = "Invalid credentials"
			end
		end
	end

	def loginfido
		# If user is logged in
		if session[:is_logged_in] && session[:is_logged_in] == true
			# goto Dashboard
			redirect_to(:action => 'dashboard') and return
		end
	end

	def logout
		# Clear session
		session[:user_id] = 0
		session[:user_email] = ""
		session[:user_name] = ""
		session[:is_logged_in] = false
		reset_session();
		# Go to index
		redirect_to(:action => 'index') and return
	end

	def register
		# If user is logged in
		if session[:is_logged_in] && session[:is_logged_in] == true
			# goto Dashboard
			redirect_to(:action => 'dashboard') and return
		end

		# If this was a post
		if request.post?
			# Try to find the user and authenticate him
			begin
				user = User.create!(name: params["name"], email: params["email"], password: params["password"], password_confirmation: params["password_confirmation"])
			rescue ActiveRecord::RecordInvalid
				user = nil
			end
			# If user was created
			if user
				# Show success message
				@message_success = "Your account was created"

			# Failed to create user
			else
				# Show error message
				@message_error = "Failed to create account"
			end
		end
	end

	def dashboard
		# If user is not logged in
		if !session[:is_logged_in] || session[:is_logged_in] == false
			# goto login
			redirect_to(:action => 'login') and return
		end

		# If logged in, get user
		user = User.find_by(id: session[:user_id])
		# If user was not found, go to logout
		if !user
			redirect_to(:action => 'logout') and return
		end
	end

	def manage
		# If user is not logged in
		if !session[:is_logged_in] || session[:is_logged_in] == false
			# goto login
			redirect_to(:action => 'login') and return
		end

		# If logged in, get user
		user = User.find_by(id: session[:user_id])
		# If user was not found, go to logout
		if !user
			redirect_to(:action => 'logout') and return
		end

		# If this was a post
		if request.post?
			if params.include?(:external_id) && params.include?('delete-btn')
				key = user.credentials.where(:external_id => params[:external_id])
				if key
					user.credentials.destroy(key)
					@message_success = 'Key was deleted!';
				else
					@message_error = 'Failed to delete the key.';
				end
			end
		end

		# Get keys
		@keys = user.credentials.select(:external_id, :public_key)
	end

	rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_referer_or_path
	def redirect_to_referer_or_path
		#@message_error = 'Please try again.'
		redirect_to request.referer + "?error=invalid-csrf"
	end
end
