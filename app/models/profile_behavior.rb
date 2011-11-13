module ProfileBehavior
  extend ActiveSupport::Concern

  included do
    after_create :set_preferred_profile
  end

  module InstanceMethods
    def full_name
      "#{first_name} #{last_name}".strip
    end

    def first_name_or_anonymous
      first_name.blank? ? "Anonymous" : first_name
    end

    def visible_name
      "#{first_name.blank? ? "Matcher #{player_id}" : first_name}#{" #{last_name[0,1]}." unless last_name.blank?}"
    end

    def name_age_and_place
      "#{visible_name}#{" (#{age} yrs)" unless age.blank?}#{" from #{location_name}" unless location_name.blank?}"
    end

    def age
      ((Date.today - birthdate).to_f / 365).to_i unless birthdate.nil?
    end

    def set_preferred_profile
      player.update_attribute(:preferred_profile, self) if player.preferred_profile.nil?
    end

    def sexual_orientation
      "u"
    end
  end
end
