class User < ApplicationRecord
	has_secure_password

	has_many :credentials, dependent: :destroy
	
	NAME_REGEX = /\A[A-Z0-9][A-Z0-9_]+\z/i
	EMAIL_REGEX = /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\z/i
	validates :name, :presence => true, :uniqueness => true, :length => { :in => 3..20 }, :format => NAME_REGEX
	validates :email, :presence => true, :uniqueness => true, :format => EMAIL_REGEX

	after_initialize do
		self.webauthn_id ||= WebAuthn.generate_user_id
	end

	#validates_presence_of :email
	#validates_uniqueness_of :email
end
