class TapjoyController < ApplicationController
  before_filter :verify_signature

  def complete
    TapjoyOffer.create(:user => User.find(params[:snuid]), :credits => params[:currency], :tapjoy_id => params[:id])
    render :text => "OK"
  end

  protected

  def verify_signature
    if TapjoyOffer.signature_valid?(params, params[:verifier])
      true
    else
      head 403 and return false
    end
  end
end

__END__

/tapjoy?snuid=1&currency=10&id=1301967388&verifier=84976279ae0b537b252ec5817eb73940
