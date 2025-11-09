# frozen_string_literal: true

require 'sequel'

class Post < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :mobility
  translates :title, backend: :key_value, type: :string, fallbacks: { ua: :en }
  translates :content, backend: :key_value, type: :text, fallbacks: { ua: :en }

  many_to_one :user

  def validate
    super
    errors.add(:user_id, I18n.t('models.errors.empty')) if self.user_id.nil?
    errors.add(:title, I18n.t('models.errors.empty')) if self.title.to_s.empty?
    errors.add(:content, I18n.t('models.errors.empty')) if self.content.to_s.empty?
  end
end
