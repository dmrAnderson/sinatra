# frozen_string_literal: true

require 'sequel'
require 'bcrypt'

class Subscription < Sequel::Model
  plugin :timestamps, update_on_create: true

  many_to_one :user
  many_to_one :plan

  def end_date
    return self.deactivated_at unless self.deactivated_at.nil?

    self.created_at + 30 * 24 * 60 * 60
  end

  def expired?
    return true unless self.deactivated_at.nil?

    self.end_date < Time.now
  end
end
