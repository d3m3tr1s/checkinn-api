class RoomAllocation
	include Mongoid::Document
	field :hotelid, type: String

	field :roomno, type: String
	field :date, type: Date
	field :type, type: String
	field :resno, type: String
	field :ressno, type: Integer
	field :rsdsno, type: String
	field :name, type: String
	field :pkgcode, type: String
	field :tariff, type: Float
	field :intime, type: String
	field :outtime, type: String
	field :status, type: String
	field :shortname, type: String
	field :fxd, type: String

	index(
		[
			[ :hotelid, Mongo::ASCENDING],
			[ :roomno, Mongo::ASCENDING],
			[ :date, Mongo::ASCENDING]
		],
		unique: true
	)

	def to_csv
		[
			hotelid, roomno, date, type, resno, ressno, 
			rsdsno, name, pkgcode, tariff, intime,
			outtime,status,shortname
		].to_csv
	end
end

class Booking
	include Mongoid::Document

	field :hotelid, type: String	
	field :no, type: String
	field :bkg_sno, type: String
	field :rsd_sno, type: String
	field :atnd_by, type: String
	field :bkd_by, type: String
	field :roomno, type: String
	field :enq_no, type: String
	field :add, type: String
	field :city, type: String
	field :pin, type: String
	field :cont_no, type: String
	field :email, type: String
	field :date, type: Date
	field :time, type: String
	field :in_date, type: String
	field :in_time, type: String
	field :out_date, type: String
	field :out_time, type: String
	field :gst_code, type: String
	field :cu_name, type: String
	field :ag_code, type: String
	field :co_code, type: String
	field :status, type: String



	index(
		[
			[ :hotelid, Mongo::ASCENDING],			
			[ :no, Mongo::ASCENDING],
			[ :bkg_sno, Mongo::ASCENDING],
			[ :rsd_sno, Mongo::ASCENDING]
		],
		unique: true	
	)

	def to_csv
		[
			hotelid, no, bkg_sno, rsd_sno 
		].to_csv
	end	
end	