class JunController < ApplicationController

  def complete
    JunOffer.create(:user => User.find(params[:uid]), :credits => 1)
    render :text => "OK"
  end

end

__END__

/tapjoy?snuid=1&currency=10&id=1301967388&verifier=84976279ae0b537b252ec5817eb73940
