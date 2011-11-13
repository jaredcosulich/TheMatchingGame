# -*- coding: undecided -*-
# =============================================================================
#
# copyright 2009 jambool
#
# ============================================================================
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# =============================================================================

# =============================================================================
# Sample client for the Social Gold Currency API V1
#
# Methods that make a call to the service:
#   - get_balance
#   - debit_user
#   - credit_user
#   - refund_user
#   - get_transactions
#   - buy_goods(format == xml || format == json)
#   - get_transaction_status
#
#  Methods that generate a URL for merchant to render in a page:
#   - get_buy_currency_url
#   - buy_goods(format == html || format == iframe)
#
# =============================================================================

require 'digest/md5'
require 'rubygems'
require 'base64'
require 'net/http'
require 'net/https'
#require 'json/add/rails'
require 'cgi'
require 'logger'
require 'uuid'

# -----------------------------------------------------------------------------

class CurrencyClient

  # ----------------------------------------------------------------------------
  def initialize(server_name, server_port, offer_id, secret_merchant_key,logger, is_production=true)
    @server_name = server_name
    @server_port = server_port
    @is_production=is_production
    @offer_id = offer_id
    @secret_merchant_key = secret_merchant_key
    @logger = logger
  end

  # ----------------------------------------------------------------------------

=begin

Purpose :

  Get the user's balance

Pre-Condition :

  user_id                : The unique ID of the user
  error_on_unknown_user  : True to return code 404 error OR False to return 0
  format                 : json OR plaintext OR xml

Post-Condition :

  It returns the user's balance (integer, with implied decimal) in the format specified

=end
  # ----------------------------------------------------------------------------

  def get_balance(user_id, format='json', error_on_unknown_user=false )
    @logger.debug("get_balance : user_id=#{user_id} error_on_unknown_user=#{error_on_unknown_user} format=#{format}")
    base_params = {:user_id => user_id, :action => 'get_balance', :format => format, :offer_id => @offer_id}
    required_params = nil
    optional_params = {:error_on_unknown_user => (error_on_unknown_user ? 1 : 0 )}

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    response = _get_response(cmd_uri)
    return response

  end

  # ----------------------------------------------------------------------------

=begin

Purpose :

  Get the status of a transaction

Pre-Condition :

  user_id                : The unique ID of the user
  format                 : json OR xml

Post-Condition :

  It returns the status of the refered transacton in the format specified, eg: { 'open':true, 'paid':false }

=end
  # ----------------------------------------------------------------------------

  def get_transaction_status(user_id, externalRefID, format='json' )
    @logger.debug("get_transaction_status : user_id=#{user_id} externalRefID=#{externalRefID} format=#{format}")
    base_params = {:user_id => user_id, :action => 'get_transaction_status', :format => format, :offer_id => @offer_id}
    required_params = {:external_ref_id => externalRefID}
    optional_params = nil

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    response = _get_response(cmd_uri)
    return response

  end

=begin
Purpose :

  Enable the user to buy premium currency through SocialGold by providing a UI interface

Pre-Condition :

  user_id         : The unique ID of the user
  appParams       : The application ID
  showBalance     : To show the updated balance after the transaction went through
  format          : iframe or HTML

Post-Condition :

  Return a URL of the buy currency User Interface

=end
  # ----------------------------------------------------------------------------

  def get_buy_currency_url(userID, appParams=nil, showBalance=true, format='iframe')
    @logger.debug("get_buy_currency_url : user_id=#{userID} appParams=#{appParams} showBalance=#{showBalance} format=#{format}")
    base_params = {:user_id => userID, :action => 'buy_currency', :format => format, :offer_id => @offer_id}
    required_params = nil
    optional_params = { :show_balance => (showBalance ? 1 : 0), :external_ref_id => UUID.generate(:compact) }
    optional_params[:app_params] = appParams if !(appParams.nil?)

    port = (@server_port == :defaults) ? "" : ":#{@server_port}"
    url = "https://#{@server_name}#{port}"
    url << _generate_uri(base_params, required_params, optional_params)
    return url

  end

=begin
Purpose :

  To record the user transaction when a user bought virtual goods

Pre-Condition :

  user_id         : The unique ID of the user
  name            : The name of the virtual good that the user bought
  pcAmount        : The amount that the user pay for the virtual good
  format          : iframe or HTML or json
  quantity        : How number of similiar item the user bought.
  sku             : string with arbitrary value, unique representation of this item in your world
  sku_category    : the category title for this sku item (if relevant)
  option_name_0   : could be size
  option_value_0  : value of option_name_0
  option_name_1   : could be color
  option_value_1  : value of option_name_1
  externalRefID   : Your own uniquie ID for reference

Post-Condition :

  Return a URL of the buy currency User Interface

=end
  # ----------------------------------------------------------------------------
  def buy_goods(userID, name, pcAmount, quantity, format='iframe', externalRefID=nil, option_name_0=nil, option_value_0=nil, option_name_1=nil, option_value_1=nil, appParams=nil, sku=nil, sku_category=nil)
    @logger.debug("buy_goods : user_id=#{userID} pcAmount=#{pcAmount} quantity=#{quantity} format=#{format} option_name_0=#{option_name_0} option_value_0=#{option_value_0} option_name_1=#{option_name_1} option_value_1=#{option_value_1} externalRefID=#{externalRefID} appParams=#{appParams} sku=#{sku} sku_category=#{sku_category}")

    base_params = {:user_id => userID, :action => 'buy_goods', :format => format, :offer_id => @offer_id}
    required_params = {:name => name, :amount => pcAmount, :quantity => quantity}
    optional_params = Hash.new
    optional_params[:app_params] = appParams if !(appParams.nil?)
    optional_params[:external_ref_id] = externalRefID if !(externalRefID.nil?)
    optional_params[:option_name_0] = option_name_0 if !(option_name_0.nil?)
    optional_params[:option_value_0] = option_value_0 if !(option_value_0.nil?)
    optional_params[:option_value_1] = option_value_1 if !(option_value_1.nil?)
    optional_params[:option_name_1] = option_name_1 if !(option_name_1.nil?)
    optional_params[:sku] = sku if !(sku.nil?)
    optional_params[:sku_category] = sku_category if !(sku_category.nil?)

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    if format.eql?("json") || format.eql?("xml")
      response = _get_response(cmd_uri)
      return response
    else
      port = (@server_port == :defaults) ? "" : ":#{@server_port}"
      url = "https://#{@server_name}#{port}#{cmd_uri}"
      @logger.debug("buy_goods: url = #{url}")
      return url
    end

  end

=begin

Purpose :

  To refund the user virtual currency

Pre-Condition :

  user_id                     : The unique ID of the user
  socialgoldTransactionID     : The unique ID of the particular transaction
  externalRefID               : Your own uniquie ID for reference
  description                 : Could be the reason why the user was refunded
  format                      : Type of return format (json or xml)

Post-Condition :

  Return result that shows "socialgold_transaction_id", "socialgold_transaction_status" and "user_balance"

=end
  # ----------------------------------------------------------------------------
  def refund_user(userID, socialgoldTransactionID, externalRefId, description=nil, format='json')
    @logger.debug("refund_user : userID=#{userID} socialgoldTransactionID=#{socialgoldTransactionID} externalRefId=#{externalRefId} description=#{description} format=#{format}")
    base_params = {:user_id => userID, :action => 'refund', :format => format, :offer_id => @offer_id}
    required_params = {:socialgold_transaction_id => socialgoldTransactionID, :external_ref_id => externalRefId}
    optional_params = {:description => description}

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    response = _get_response(cmd_uri)
    return response
  end


=begin

Purpose :

  To return a sorted list of the particular user transaction

Pre-Condition :

  user_id         : The unique ID of the user
  startTimestamp  : The starting date for wanted transaction
  endTimestamp    : The endign date for the wanted transaction
  format          : html OR json OR xml OR csv
  limit           : Limit the result set returned
  orderByCol0     : Sort according to the value stated
  orderByDir0     : "asc" or "desc"
  orderbyCol1     : Sort According to the value stated
  orderByDir1     : "asc" or "desc"

Post-Condition :

  Return a list of user's transaction with details

   - socialgold_transaction_id
   - socialgold_transaction_status
   - user_id
   - amount
   - credit or debit
   - timestamp
   - external_ref_id
   - description
=end
  # ----------------------------------------------------------------------------
  def get_transactions(user_id, startTimestamp, format='json', endTimestamp=nil, limit=nil, orderByCol0=nil, orderByDir0=nil, orderByCol1=nil, orderByDir1=nil)
    @logger.debug("get_transaction : user_id=#{user_id} startTimestamp=#{startTimestamp} format=#{format} endTimestamp=#{endTimestamp} limit=#{limit} orderByCol0=#{orderByCol0} orderByDir0=#{orderByDir0} orderByCol1=#{orderByCol1} orderByDir1=#{orderByDir1}")

    base_params = {:user_id => user_id, :action => 'get_transactions', :format => format, :offer_id => @offer_id}
    required_params = {:start_ts => startTimestamp}

    optional_params = Hash.new
    optional_params[:end_ts] = endTimestamp if (endTimestamp.to_i > 0) && !(endTimestamp.nil?)
    optional_params[:limit] = limit if (limit.to_i > 0) && !(limit.nil?)
    optional_params[:order_by_column_0] = orderByCol0 if !(orderByCol0.nil?)
    optional_params[:order_by_dir_0] = orderByDir0 if !(orderByDir0.nil?)
    optional_params[:order_by_column_1] = orderByCol1 if !(orderByCol1.nil?)
    optional_params[:order_by_dir_1] = orderByDir1 if !(orderByDir1.nil?)

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    response = _get_response(cmd_uri)
    return response

  end
  # ----------------------------------------------------------------------------

=begin

Purpose :

  To debit the user's account (deduct amount from user's balance)

Pre-Condition :

  user_id                     : The unique ID of the user
  amount                      : Amount to be debited from the user's account
  externalRefID               : Your own uniquie ID for reference
  description                 : Could be the reason why the user was debited
  format                      : Type of return format (json or xml)

Post-Condition :

  Return result that shows "socialgold_transaction_id", "socialgold_transaction_status" and "user_balance"

  "1001: insufficient funds" error will be returned if a debit would create a negative balance.

=end

  def debit_user(user_id, amount, description, external_ref_id, format='json')
    @logger.debug("debit_user : user_id=#{user_id} amount=#{amount} description=#{description} external_ref_id=#{external_ref_id} format=#{format}")
    base_params = {:user_id => user_id, :action => 'debit', :format => format, :offer_id => @offer_id}
    required_params = {:amount => amount, :external_ref_id => external_ref_id, :description => description}
    optional_params = nil
    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    reponse = _get_response(cmd_uri)
    return reponse
    #suppose to send the cmd_uri to social gold server and get the response. (not sure how yet)
  end

  # ----------------------------------------------------------------------------

  def get_valid_credit_types()
    return [ :new_user_credit, :item_sold_credit, ]
  end

  # ----------------------------------------------------------------------------

=begin

Purpose :

  To credit the user's account (increase amount from user's balance)

Pre-Condition :

  user_id                     : The unique ID of the user
  amount                      : Amount to be debited from the user's account
  externalRefID               : Your own uniquie ID for reference
  description                 : Could be the reason why the user was credited
  format                      : Type of return format (json or xml)
  credit_type                 : new_user_credit OR item_sold_credit

Post-Condition :

  Return result that shows "socialgold_transaction_id", "socialgold_transaction_status" and "user_balance"

  new_user_credit can be used only once.

=end

  def credit_user(user_id, amount, external_ref_id, credit_type, description =nil, format = 'json')
    raise "Error, Invalid credit_type : #{credit_type}" if( ! get_valid_credit_types.include?(credit_type.to_sym))
    @logger.debug("credit_user : user_id=#{user_id} amount=#{amount} description=#{description} external_ref_id=#{external_ref_id} format=#{format} credit_type=#{credit_type}")
    base_params = {:user_id => user_id, :action => 'credit', :format => format, :offer_id => @offer_id}
    required_params = {:amount => amount, :external_ref_id => external_ref_id, :description => description, :credit_type => credit_type.to_s}
    optional_params = nil

    cmd_uri = _generate_uri(base_params, required_params, optional_params)
    reponse = _get_response(cmd_uri)
    return reponse
  end




  # ===  PRIVATE  ==============================================================

=begin

Purpose :

  To generate the the URL for socialgold server (includes signing of of the parameters)

Pre-Condition :

  baseParams                  : Parameters that is required for all methods
  requiredParams              : Parameters that is required specfic to the method
  optionalParams              : Parameters that is optional for the specific method

Post-Condition :

  Return the URL

=end

  private
  def _generate_uri(baseParams, requiredParams, optionalParams)

    signature_params = {:user_id => baseParams[:user_id], :action => baseParams[:action], :ts => Time.now.to_i, :offer_id => baseParams[:offer_id] }
    format = baseParams[:format]

    signature_params.merge!(requiredParams) if !(requiredParams.nil?)

    signature_params.merge!(optionalParams) if !(optionalParams.nil?)

    signature_params.delete_if {|key, value| value == nil}

    to_sign = signature_params.collect{|tuple| tuple.first}.collect{|k| k.to_s}.sort. # sort the keys
      collect{ |k| k + signature_params[k.to_sym].to_s }.join('') # create canonical string

    calculated_signature = Digest::MD5.hexdigest(to_sign + @secret_merchant_key)

    url = ""

    send_uri = "/socialgold/v1/#{@offer_id}/#{baseParams[:user_id]}/#{baseParams[:action]}?sig=#{calculated_signature}&ts=#{signature_params[:ts]}&format=#{format}"

    send_uri << _convert_hash_to_uri(requiredParams) if !(requiredParams.nil?)

    send_uri << _convert_hash_to_uri(optionalParams) if !(optionalParams.nil?)

    url << send_uri

    @logger.debug(" - Sending request to: #{url}")

    return url

  end

  # ----------------------------------------------------------------------------
=begin

Purpose :

  To convert the values in hash into a URL format "&variable_name=value&value=2&"

Pre-Condition :

  target_hash  : hash that contains values needed to convert into URL format

Post-Condition :

  Return a string with the correct URI format

=end

  private
  def _convert_hash_to_uri(target_hash) #converting them into URL format &variable_name=value&value=2&....
    url = ""
    target_hash.each_pair { |key,value|
      url << "&#{key}=#{CGI.escape(value.to_s)}" if !value.nil?
    }
    return url
  end

  # ----------------------------------------------------------------------------
  private
  def _get_response(cmd_uri, use_ssl=true)
    http_client = Net::HTTP.new(@server_name, @server_port)
# Matching Game Edit - wasn't working with ssl
#    http_client.use_ssl = true
#    http_client.ssl_timeout = 5
    http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE

    result = {}
    http_client.start do |http|
      request = Net::HTTP::Get.new(cmd_uri)
      response = http_client.request(request)
      result[:body] = response.body
      result[:code] = response.code
    end
    return result
  end
end

# =============================================================================

if __FILE__ == $0

#========== TESTING PHRASE=================================

logfile = File.join( "sg_client_test.log" )
STDERR.puts( "logging to #{logfile}" )
@logger = Logger.new( logfile )

offer_id = 'socialgolddemoofferid123'
secretMerchantKey = "lxh17hau9jifrrcbv9mwghg9z"
api_server_name = "api.sandbox.jambool.com"
# api_server_port = "3000"
api_server_port = :defaults
is_production = false

currency_client = CurrencyClient.new(api_server_name,api_server_port,offer_id,secretMerchantKey,@logger,is_production)

result = nil
user_id = nil
pc_amount = 100
external_ref_id =  nil
description =  nil
format="xml"
url=nil
credit_type=nil

STDERR.puts("Start Testing Function")
STDERR.puts("================================== get_balance ================================================")
user_id = "demo_user_id"

response = currency_client.get_balance(user_id)

STDERR.puts("#{response.inspect}")

user_id = "unknown_user_id"
format='json'

response = currency_client.get_balance(user_id, format, true)

STDERR.puts("#{response.inspect}")

STDERR.puts("================================== credit user =========================")

user_id = "demo_user_id"
pc_amount = 888
description = "ruby credit user description Rawk!"
credit_type = :new_user_credit
external_ref_id = rand(1000000)
response = currency_client.credit_user(user_id,pc_amount,external_ref_id,credit_type,description)

STDERR.puts("Printing credit_user : with default format json = #{response.inspect}")
external_ref_id = rand(1000000)
response = currency_client.credit_user(user_id,pc_amount,external_ref_id,credit_type,description, format)

STDERR.puts("Printing credit_user with xml format = #{response.inspect}")

credit_type = :item_sold_credit
external_ref_id = rand(1000000)
response = currency_client.credit_user(user_id,pc_amount,external_ref_id,credit_type,description)

STDERR.puts("Printing credit_user : with default format json (:item_sold_credit)= #{response.inspect}")

external_ref_id = rand(1000000)
response = currency_client.credit_user(user_id,pc_amount,external_ref_id,credit_type,description, format)

STDERR.puts("Printing credit_user with xml format (:item_sold_credit) = #{response.inspect}")


STDERR.puts("================================== Debit user ============================")
description = "I am buying some cool stuff"
external_ref_id = rand(1000000)
response =  currency_client.debit_user(user_id, pc_amount, description, external_ref_id)

STDERR.puts("debit_user = #{response.inspect}")

external_ref_id = rand(1000000)
response =  currency_client.debit_user(user_id, pc_amount, description, external_ref_id, format)

STDERR.puts("debit_user with format xml = #{response.inspect}")

STDERR.puts("==================================== get_buy_currency_url =======================")

STDERR.puts("get_currency_url")

url_return = currency_client.get_buy_currency_url(user_id, "appID123", true)

STDERR.puts("#{url_return}")

url_return = currency_client.get_buy_currency_url(user_id)

STDERR.puts("with only user_id : #{url_return}")

STDERR.puts("==================================== buy_goods ==================================")

STDERR.puts("buy_goods")
quantity = 1
format = 'json'
external_ref_id = rand(1000000)
response = currency_client.buy_goods(user_id, "fake_sword!", pc_amount, quantity, format,external_ref_id)

STDERR.puts("format : json : #{response.inspect}")

format = 'iframe'
external_ref_id = rand(1000000)
url_return = currency_client.buy_goods(user_id, "fake_sword!", pc_amount, quantity,format, external_ref_id)

STDERR.puts("default format : iframe : #{url_return}")

STDERR.puts("==================================== get_transaction_status =====================")

STDERR.puts("get_transaction_status")
format = 'json'
external_ref_id = 309544
response = currency_client.get_transaction_status(user_id, external_ref_id, format)

STDERR.puts("format : json : #{response.inspect}")


STDERR.puts("============================== user transaction history ================================")

STDERR.puts("User_transaction")
end_time_stamp = nil
# start_time_stamp = 1
start_time_stamp = Time.now.to_i - (60*60*24*30) # go back about 30 days ...
limit=20

# response = currency_client.get_transactions(user_id, start_time_stamp)
response = currency_client.get_transactions(user_id, start_time_stamp, format, end_time_stamp, limit)

STDERR.puts("#{response.inspect}")

# STDERR.puts("=========================== refund ==================================================")
# STDERR.puts("<E> User_Refund")
#
# url_return = currency_client.refund_user(user_id, socialgold_transaction_id, external_ref_id)
#
# STDERR.puts("<E> #{url_return}")
#
#
# STDERR.puts("<E> DONE")

end


# =============================================================================
# EOF
# =============================================================================
