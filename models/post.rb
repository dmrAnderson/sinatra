# frozen_string_literal: true

require 'sequel'

class Post < Sequel::Model
  plugin :timestamps, update_on_create: true

  many_to_one :user

  def validate
    super
    errors.add(:user_id, "can't be empty") if self.user_id.nil?
    errors.add(:title, "can't be empty") if self.title.empty?
    errors.add(:content, "can't be empty") if self.content.empty?
  end
end
