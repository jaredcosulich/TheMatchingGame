class Admin::BounceRate
  extend Garb::Resource
  metrics :visits, :bounces
  dimensions :date
end
