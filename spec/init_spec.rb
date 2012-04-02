require 'spec_helper'

describe "Checkinn API" do

  it "should respond to GET" do
    get '/'
    last_response.should be_ok
    last_response.body.should match(/API/)
  end

  it "should create booking record from POST data in CSV format" do
    date = "2012-04-01"
    time = "17:40:00"
    csv_string = CSV.generate do |csv|
                  csv << {:no => "WEB000002",:bkg_sno => 1, :rsd_sno => 1,
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 1, 
                  :date => date, :time => time}.values

                  csv << {:no => "WEB000002",:bkg_sno => 2, :rsd_sno => 1,
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 1, 
                  :date => date, :time => time}.values

                  csv << {:no => "WEB000002",:bkg_sno => 3, :rsd_sno => 1,
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 1, 
                  :date => date, :time => time}.values                  

    end    
  	post '/hotel/1/booking/csv', csv_string
  	last_response.should be_ok 
    last_response.body.should match(/1,WEB000002/)
  end	

  it "should return list of bookings stating from date" do
    date = "2012-04-01"
    time = "17:40:00"
    get '/hotel/1/bookings/from/2012-04-01/csv'
    last_response.should be_ok
    last_response.body.should match(/1,WEB000002/)
  end

end