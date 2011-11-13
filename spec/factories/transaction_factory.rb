Factory.define :transaction do |t|
  t.association :user
end

Factory.define :initial_credits, :parent => :transaction do |c|
  c.amount 100
  c.after_build {|transaction| transaction.source = transaction.user}
end

