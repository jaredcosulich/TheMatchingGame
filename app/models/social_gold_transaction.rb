class SocialGoldTransaction < ActiveRecord::Base
  class InvalidSignature < StandardError; end;

  belongs_to :user

  serialize :extra_fields

  def initialize(params)
    SocialGoldTransaction.verify_signature(params.delete("signature"), signature_params(params))
    extra_fields = {}
    params.each_key { |k| extra_fields[k] = params.delete(k) unless SocialGoldTransaction.column_names.include?(k.to_s) }
    super(params.merge({:extra_fields => extra_fields}))
  end

  def signature_params(params)
    if params.has_key?("offer_id")
      {"timestamp" => params.delete("timestamp")}
    else
      params
    end
  end

  def self.buy_credits_url(user)
    SocialGoldTransaction.currency_client.get_buy_currency_url(user.id)
  end

  def self.subscribe_url(user)
    now = Time.now.to_i
    raw_signature = canonicalize("action" => "show_form", "ts" => now, "subscription_offer_id" => SOCIAL_GOLD_OPTIONS[:subscription_offer], "user_id" => user.id) + SOCIAL_GOLD_OPTIONS[:secret_key]
    signature = Digest::MD5.hexdigest(raw_signature)
    <<-HTML
      https://#{::SOCIAL_GOLD_OPTIONS[:server]}/socialgold/subscription/v1/#{SOCIAL_GOLD_OPTIONS[:subscription_offer]}/#{user.id}/show_form/?ts=#{now}&sig=#{signature}
    HTML
  end

  def self.unlock_url(user, return_url)
    now = Time.now.to_i
    raw_signature = canonicalize("action" => "buy_currency", "ts" => now, "offer_id" => SOCIAL_GOLD_OPTIONS[:virtual_currency_offer], "user_id" => user.id, "return_url" => return_url) + SOCIAL_GOLD_OPTIONS[:secret_key]
    signature = Digest::MD5.hexdigest(raw_signature)
    <<-HTML
      https://#{::SOCIAL_GOLD_OPTIONS[:server]}/socialgold/v1/#{SOCIAL_GOLD_OPTIONS[:virtual_currency_offer]}/#{user.id}/buy_currency/?format=iframe&return_url=#{return_url}&ts=#{now}&sig=#{signature}
    HTML
  end

  def self.verify_signature(signature, signature_params)
    to_sign = canonicalize(signature_params) + SOCIAL_GOLD_OPTIONS[:secret_key]
    expected_signature = Digest::MD5.hexdigest(to_sign)
    raise InvalidSignature.new("expected signature #{expected_signature} but got #{signature}") unless expected_signature == signature
  end

  def self.canonicalize(signature_params)
    signature_params.collect{|tuple| tuple.first}.collect{|k| k.to_s }.sort. # sort the keys
      collect{ |k| "#{k}#{signature_params[k]}" }.join('') # create canonical string
  end

  def self.get_premium_currency_amount(user_id, external_ref_id)
    Timeout.timeout 3 do
      body = currency_client.get_transactions(user_id, 1.hour.ago.to_i)[:body]
      transactions = JSON.parse(body)["transactions"]
      selected_transaction = transactions.detect {|t| t["external_ref_id"] == external_ref_id }
      selected_transaction["premium_currency_amount"].to_i
    end
  rescue => e
    raise e if Rails.env.development?
    HoptoadNotifier.notify(e)
  end

  def self.currency_client
    CurrencyClient.new(SOCIAL_GOLD_OPTIONS[:server], nil, SOCIAL_GOLD_OPTIONS[:virtual_currency_offer], SOCIAL_GOLD_OPTIONS[:secret_key], logger, Rails.env.production?)
  end
end
