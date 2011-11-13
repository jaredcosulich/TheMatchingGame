#
# Inspired by
# http://dev.rubyonrails.org/svn/rails/plugins/account_location/lib/account_location.rb
#
module SubdomainLocales
  def self.included( controller )
    controller.helper_method(:locale_subdomain, :locale_subdomain_style, :locale_subdomain_location)
  end

  def locale_subdomain
    (request.subdomains.first == 'www' || request.subdomains.first == 'staging') ? nil : request.subdomains.first
  end

  def locale_subdomain_style
    locale_subdomain == "sf" ? locale_subdomain : "site"
  end

  def locale_subdomain_location
    locale_subdomain == "sf" ? "San Francisco, CA" : ""
  end

  def locale_subdomain_edition
    locale_subdomain == "sf" ? "(bay area edition)" : ""
  end

  def locale_subdomain_area
    locale_subdomain == "sf" ? "the bay area" : ""
  end

end
