require 'spec_helper'

describe "Checkinn API" do

  it "should respond to GET" do
    get '/'
    last_response.should be_ok
    last_response.body.should match(/API/)
  end

  it "should create booking record from POST data in CSV format" do
  	post '/hotel/:id/booking/format/csv', {
  		:no => "WEB000002",
  		:bkg_sno => 1,
  		:rsd_sno => 1,
  		:atnd_by => "Dmitry",
  		:bkd_by => 'WEB',
  		:roomno => 1,
  		:date => Date.today.to_s,
  		:time => Time.now.strftime("%T")
  	}.values.to_csv
  	last_response.should be_ok, last_response.body	
  end	

end