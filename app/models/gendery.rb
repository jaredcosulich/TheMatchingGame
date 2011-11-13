module Gendery
  def has_gender?
    ['m', 'f'].include?(gender)
  end

  def he_she
    return "he" if gender == "m"
    return "she" if gender == "f"
    return "they"
  end

  def his_her
    return "his" if gender == "m"
    return "her" if gender == "f"
    return "their"
  end

  def him_her
    return "him" if gender == "m"
    return "her" if gender == "f"
    return "them"
  end

  def full_gender
    gender.nil? ? "na" : (gender == "m" ? "male" : "female")
  end

  def self.opposite(gender)
    case gender
      when "m" then "f"
      when "f" then "m"
      else ""
    end
  end
end
