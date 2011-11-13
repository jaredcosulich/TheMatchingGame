class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << (options[:message] || "is not a valid email") unless value =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  end
end

class DifferentGendersValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if record.photo_one.gender == record.photo_two.gender
      record.errors.add(:photo_two, "Photo genders should be different")
    end
  end
end
