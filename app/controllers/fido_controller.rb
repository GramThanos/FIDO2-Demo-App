class FidoController < ApplicationController
	def auth
		# If user is logged in
		if session[:is_logged_in] && session[:is_logged_in] == true
			render json: {
				error: "Already logged in."
			}, status: :not_found and return
		end

		# If this was a post
		if request.post?
			# If user email, then create a challenge
			if params.include?(:userid)
				# Try to find the user and authenticate him
				user = nil
				if params["userid"].include?('@')
					user = User.find_by(email: params["userid"])
				else
					user = User.find_by(name: params["userid"])
				end
				# If user was not found
				if !user
					render json: {
						error: "Account was not found."
					}, status: :not_found and return
				end

				# Check if user has authenticator
				if !user.webauthn_id
					render json: {
						error: "Account does not have authenticator."
					}, status: :not_found and return
				end

				# Credential Authentication - Initiation phase
				options = WebAuthn::Credential.options_for_get(allow: user.credentials.map { |c| c.external_id })
				session[:user_email] = user.email
				session[:authentication_challenge] = options.challenge
				render json: {
					success: "Challenge started.",
					options: options
				}, status: :ok and return

			# If challenge
			elsif params.include?(:publicKeyCredential)
				# If no session data
				if !session[:user_email] || !session[:authentication_challenge]
					render json: {
						error: "Invalid request."
					}, status: :not_found and return
				end

				# Credential Authentication - Verification phase
				webauthn_credential = WebAuthn::Credential.from_get(params[:publicKeyCredential])

				user = User.find_by(email: session[:user_email])
				stored_credential = user.credentials.find_by(external_id: webauthn_credential.id)

				begin
					challenge = session[:authentication_challenge]
					session.delete(:authentication_challenge)
					webauthn_credential.verify(
						challenge,
						public_key: stored_credential.public_key,
						sign_count: stored_credential.sign_count
					)

					# Update the stored credential sign count with the value from `webauthn_credential.sign_count`
					stored_credential.update!(sign_count: webauthn_credential.sign_count)

					# Login user
					# Set session info
					session[:user_id] = user.id
					session[:user_email] = user.email
					session[:user_name] = user.name
					session[:is_logged_in] = true

					# Response message
					render json: {
						success: "Successful login."
					}, status: :ok and return

				rescue WebAuthn::SignCountVerificationError => e
					# Cryptographic verification of the authenticator data succeeded, but the signature counter was less then or equal
					# to the stored value. This can have several reasons and depending on your risk tolerance you can choose to fail or
					# pass authentication. For more information see https://www.w3.org/TR/webauthn/#sign-counter
					render json: {
						success: "Authentication failed."
					}, status: :not_found and return

				rescue WebAuthn::Error => e
					render json: {
						success: "Authentication error."
					}, status: :not_found and return
				end
			end
		end

		# If it was a get request
		render json: {
			error: "Invalid request."
		}, status: :not_found and return
	end

	def set
		# If user is not logged in
		if !session[:is_logged_in] || session[:is_logged_in] == false
			render json: {
				error: "User is not logged in."
			}, status: :not_found and return
		end

		# If this was a post
		if request.post?
			# Get user
			user = User.find_by(id: session[:user_id])

			# If no credentials
			if !params.include?(:publicKeyCredential)
				# Credential Registration - Initiation phase
				if !user.webauthn_id
					user.update!(webauthn_id: WebAuthn.generate_user_id)
				end
				options = WebAuthn::Credential.options_for_create(
					user: { id: user.webauthn_id, name: user.name },
					exclude: user.credentials.map { |c| c.external_id }
				)
				# Store the newly generated challenge somewhere so you can have it
				# for the verification phase.
				session[:creation_challenge] = options.challenge

				render json: {
					success: "Challenge started.",
					options: options
				}, status: :ok and return

			# If challenge
			elsif params.include?(:publicKeyCredential)
				# Credential Registration - Verification phase
				webauthn_credential = WebAuthn::Credential.from_create(params[:publicKeyCredential])

				begin
					challenge = session[:creation_challenge]
					session.delete(:creation_challenge)
					webauthn_credential.verify(challenge)

					# Store Credential ID, Credential Public Key and Sign Count for future authentications
					user.credentials.create!(
						external_id: webauthn_credential.id,
						public_key: webauthn_credential.public_key,
						sign_count: webauthn_credential.sign_count
					)

					# Response message
					render json: {
						success: "Successful authenticator registration."
					}, status: :ok and return

				rescue WebAuthn::Error => e
					render json: {
						success: "Authentication error."
					}, status: :not_found and return
				end
			end
		end

		# If it was a get request
		render json: {
			error: "Invalid request."
		}, status: :not_found and return
	end

	def get
		# If user is not logged in
		if !session[:is_logged_in] || session[:is_logged_in] == false
			render json: {
				error: "User is not logged in."
			}, status: :not_found and return
		end

		# Get user
		user = User.find_by(id: session[:user_id])
		
		render json: {
			success: "Keys list",
			keys: user.credentials.select('external_id AS keyid', 'public_key AS pubkey').as_json(:except => :id)
		}, status: :ok and return
	end
end
