require 'spec_helper'

describe "Checkinn API" do

  it "should respond to GET" do
    get '/'
    last_response.should be_ok
    last_response.body.should match(/API/)
  end

  it 'should create list of Room Blocked from POST data in CSV format' do
    date = "2012-04-10"
    date2 = "2012-04-11"
    csv_string = CSV.generate do |csv|
        csv << {:roomno => 50, :date => date}.values
        csv << {:roomno => 51, :date => date}.values
        csv << {:roomno => 50, :date => date2}.values
    end  
    post '/hotel/1/blocked', csv_string
    last_response.should be_ok
    last_response.body.should match(/1,50,2012-04-10/)
  end 

  it "should create booking record from POST data in CSV format" do

    date = "2012-04-01"
    time = "17:40:00"
    csv_string = CSV.generate do |csv|
                  csv << {:no => "WEB000002",:bkg_sno => 1,:roomno => 11, 
                  :cu_name => "Dmitry", :cont_no => 1234, :email => "don.iliy@gmail.com",
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values

                  csv << {:no => "WEB000002",:bkg_sno => 2 ,:roomno => 12, 
                  :cu_name => "Dmitry", :cont_no => 1234, :email => "don.iliy@gmail.com",
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values

                  csv << {:no => "WEB000002",:bkg_sno => 3, :roomno => 13, 
                  :cu_name => "Dmitry", :cont_no => 1234, :email => "don.iliy@gmail.com", 
                  :date => date, :time => time, :in_date=> "2012-04-03", :in_time=> "12:00",
                  :out_date => "2012-04-06", :out_time => "10:00"}.values                  

    end    
  	post '/hotel/1/booking', csv_string
  	last_response.should be_ok 
    last_response.body.should match(/1,WEB000002/)
  end	

  it "should return list of bookings starting from date" do
    date = "2012-04-01"
    time = "17:40:00"
    get '/hotel/1/booking/from/2012-04-01'
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

  it "should show all accesses" do
    get '/access'
    last_response.should be_ok
    last_response.body.should match(/123456789/)    
  end 

end