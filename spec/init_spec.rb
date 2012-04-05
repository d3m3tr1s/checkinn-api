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
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 11, 
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values

                  csv << {:no => "WEB000002",:bkg_sno => 2, :rsd_sno => 1,
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 12, 
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values

                  csv << {:no => "WEB000002",:bkg_sno => 3, :rsd_sno => 1,
                  :atnd_by => "Dmitry",:bkd_by => 'WEB',:roomno => 13, 
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values                  

    end    
  	post '/hotel/1/booking/csv', csv_string
  	last_response.should be_ok 
    last_response.body.should match(/1,WEB000002/)
  end	

  it "should return list of bookings stating from date" do
    date = "2012-04-01"
    time = "17:40:00"
    get '/hotel/1/booking/from/2012-04-01/csv'
    last_response.should be_ok
    last_response.body.should match(/1,WEB000002/)
  end

  it "should create new access record" do
    post '/access', params = {:key => '123456789', :secret => 'kp7Ypohjhapkido1980', :hotelid => 1}
    last_response.should be_ok
    last_response.body.should == '123456789'
  end

  it "should show single access record" do
    get '/access/123456789'
    last_response.should be_ok
    last_response.body.should match(/123456789/)
  end

  it "should should all accesses" do
    get '/access'
    last_response.should be_ok
    last_response.body.should match(/123456789/)    
  end 

end