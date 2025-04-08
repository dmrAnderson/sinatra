# frozen_string_literal: true

require 'sequel'
require 'bcrypt'

class User < Sequel::Model
  plugin :timestamps, update_on_create: true

  def password=(new_password)
    self.password_digest = BCrypt::Password.create(new_password)
  end

  def valid_password?(given_password)
    BCrypt::Password.new(password_digest) == given_password
  end

  def validate
    super
    errors.add(:email, "can't be empty") if self.email.empty?
    errors.add(:email, "already exists") if User.where(email: self.email).count > 0
    errors.add(:password_digest, "can't be empty") if self.password_digest.empty?
  end
end
